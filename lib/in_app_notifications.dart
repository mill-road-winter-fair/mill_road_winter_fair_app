// Dart SDK imports
import 'dart:async';
import 'dart:convert';
import 'dart:io';

// Third-party imports
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FairNotification {
  final String id, title, body;
  final DateTime startsAt, expiresAt;

  const FairNotification(
    this.id,
    this.title,
    this.body,
    this.startsAt,
    this.expiresAt,
  );

  bool isCurrent(DateTime now) => !now.isBefore(startsAt) && now.isBefore(expiresAt) && now.difference(startsAt) < const Duration(hours: 24);

  static List<FairNotification> parse(String body) {
    final data = jsonDecode(body);
    final rows = data is Map ? data['values'] : null;
    if (rows is! List) throw const FormatException('Missing values array');
    if (rows.isEmpty) return [];
    if (rows.first is! List) throw const FormatException('Missing headers');
    final headers = (rows.first as List).map((v) => v.toString().trim()).toList();
    const required = [
      'id',
      'title',
      'body',
      'starts_at',
      'expires_at',
      'enabled',
    ];
    if (!required.every(headers.contains) || headers.toSet().length != headers.length) {
      throw const FormatException('Invalid notification headers');
    }
    final result = <FairNotification>[];
    final ids = <String>{};
    final duplicates = <String>{};
    for (final row in rows.skip(1)) {
      if (row is! List) continue;
      String cell(String key) {
        final index = headers.indexOf(key);
        return index < row.length ? (row[index]?.toString().trim() ?? '') : '';
      }

      final id = cell('id');
      if (!ids.add(id)) duplicates.add(id);
      if (cell('enabled').toLowerCase() != 'true') continue;
      DateTime? date(String key) {
        final value = cell(key);
        // Require an explicit timezone; sheet-local dates are ambiguous.
        if (!RegExp(r'T.*(Z|[+-]\d{2}:\d{2})$').hasMatch(value)) return null;
        return DateTime.tryParse(value)?.toUtc();
      }

      final start = date('starts_at');
      final end = date('expires_at');
      if (id.isEmpty || cell('title').isEmpty || cell('body').isEmpty || start == null || end == null || !end.isAfter(start)) {
        continue;
      }
      result.add(FairNotification(id, cell('title'), cell('body'), start, end));
    }
    return result.where((n) => !duplicates.contains(n.id)).toList()..sort((a, b) => b.startsAt.compareTo(a.startsAt));
  }
}

/// Foreground-only polling. Content is never cached or replayed offline.
class FairNotificationService extends ChangeNotifier {
  FairNotificationService({
    required this.endpoint,
    required this.apiKey,
    required this.preferences,
    http.Client? client,
    DateTime Function()? now,
  })  : _client = client ?? http.Client(),
        _now = now ?? DateTime.now;

  final String endpoint, apiKey;
  final SharedPreferences preferences;
  final http.Client _client;
  final DateTime Function() _now;
  static const interval = Duration(minutes: 5);
  String get _seenKey => 'notifications_seen_v1:$endpoint';
  String get _nextKey => 'notifications_next_v1:$endpoint';
  Timer? _pollTimer;
  bool _active = false, _disposed = false, _busy = false;
  int _failures = 0;
  FairNotification? current;

  void _log(String message) {
    if (kDebugMode) debugPrint('Notifications: $message');
  }

  Future<void> setActive(bool active) async {
    _log(active ? 'foreground polling enabled' : 'polling paused');
    _active = active;
    _pollTimer?.cancel();
    if (active) {
      await poll();
    }
  }

  void dismiss() {
    current = null;
    if (!_disposed) notifyListeners();
  }

  Future<void> poll() async {
    final uri = Uri.tryParse(endpoint);
    if (!_active || _disposed || _busy || uri == null || uri.scheme != 'https' || uri.host.isEmpty || apiKey.isEmpty) {
      _log('check skipped (active=$_active, disposed=$_disposed, busy=$_busy, '
          'validEndpoint=${uri != null && uri.scheme == 'https' && uri.host.isNotEmpty}, '
          'keyConfigured=${apiKey.isNotEmpty})');
      return;
    }
    final next = DateTime.fromMillisecondsSinceEpoch(preferences.getInt(_nextKey) ?? 0);
    if (_now().isBefore(next)) {
      _log('next check at ${next.toUtc().toIso8601String()}');
      _schedule(next.difference(_now()));
      return;
    }
    _busy = true;
    var delay = interval;
    try {
      // Persist throttling so rapid app restarts cannot hammer the API.
      if (!await preferences.setInt(
        _nextKey,
        _now().add(delay).millisecondsSinceEpoch,
      )) {
        return;
      }
      final response = await _client.get(
        uri,
        headers: {
          'x-api-key': apiKey,
          'Cache-Control': 'no-cache',
        },
      ).timeout(const Duration(seconds: 15));
      _log('HTTP ${response.statusCode} from ${uri.host}${uri.path}');
      if (response.statusCode != 200) {
        final seconds = int.tryParse(response.headers['retry-after'] ?? '');
        if (seconds != null && seconds > delay.inSeconds) {
          delay = Duration(seconds: seconds);
        }
        throw const FormatException('Notification request failed');
      }
      final notifications = FairNotification.parse(response.body);
      _log('${notifications.length} valid enabled rows at ${_now().toUtc().toIso8601String()}');
      _failures = 0;
      if (!_active || _disposed || current != null) return;
      final seen = (preferences.getStringList(_seenKey) ?? []).toSet();
      for (final notification in notifications) {
        if (!notification.isCurrent(_now()) || seen.contains(notification.id)) {
          _log('skipping ID ${notification.id}: '
              'current=${notification.isCurrent(_now())}, alreadySeen=${seen.contains(notification.id)}');
          continue;
        }
        // Persist before presentation, favouring no repeats after a crash.
        if (!await preferences.setStringList(_seenKey, [...seen, notification.id])) {
          return;
        }
        if (!_active || _disposed || !notification.isCurrent(_now())) return;
        current = notification;
        _log('showing ID ${notification.id}');
        notifyListeners();
        break; // At most one dialog per poll; no burst of queued messages.
      }
    } catch (error) {
      // Do not log raw errors: HTTP exceptions can include credentials or payloads.
      _log('check failed (${error.runtimeType})');
      _failures = (_failures + 1).clamp(1, 4);
      final backoff = Duration(minutes: (5 * (1 << _failures)).clamp(5, 60));
      if (backoff > delay) delay = backoff;
      // Network, malformed data and storage failures must not disrupt the fair.
    } finally {
      if (!_disposed) {
        try {
          await preferences.setInt(
            _nextKey,
            _now().add(delay).millisecondsSinceEpoch,
          );
        } catch (_) {
          /* Retry only on the normal timer if storage is unavailable. */
        }
      }
      _busy = false;
      _schedule(delay);
    }
  }

  void _schedule(Duration delay) {
    _pollTimer?.cancel();
    if (_active && !_disposed) {
      _log('next check in ${delay.inSeconds} seconds');
      _pollTimer = Timer(delay, poll);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _pollTimer?.cancel();

    _client.close();
    super.dispose();
  }
}

class FairNotificationHost extends StatefulWidget {
  const FairNotificationHost({super.key, required this.service, required this.navigatorKey, required this.child});
  final FairNotificationService service;
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<FairNotificationHost> createState() => _FairNotificationHostState();
}

class _FairNotificationHostState extends State<FairNotificationHost> with WidgetsBindingObserver {
  bool _dialogOpen = false;
  final _dialogScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.service.addListener(_notificationChanged);
    widget.service.setActive(WidgetsBinding.instance.lifecycleState == null || WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed);
  }

  void _notificationChanged() {
    if (_dialogOpen || widget.service.current == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _dialogOpen) return;
      final notification = widget.service.current;
      final dialogContext = widget.navigatorKey.currentState?.overlay?.context;
      if (notification == null || dialogContext == null) return;
      _dialogOpen = true;
      showDialog<void>(
        context: dialogContext,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: AlertDialog(
            title: Text(notification.title),
            content: Scrollbar(
              controller: _dialogScrollController,
              thumbVisibility: Platform.isIOS ? false : true,
              thickness: 4,
              radius: const Radius.circular(8),
              child: SingleChildScrollView(
                controller: _dialogScrollController,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(notification.body),
                ),
              ),
            ),
            actionsAlignment: MainAxisAlignment.end,
            actions: [
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.service.dismiss();
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      ).whenComplete(() => _dialogOpen = false);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => widget.service.setActive(state == AppLifecycleState.resumed);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.service.removeListener(_notificationChanged);
    _dialogScrollController.dispose();
    widget.service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
