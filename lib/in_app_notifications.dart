import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FairNotification {
  final String id, title, body;
  final DateTime startsAt, expiresAt;

  const FairNotification(
      this.id, this.title, this.body, this.startsAt, this.expiresAt);

  bool isCurrent(DateTime now) =>
      !now.isBefore(startsAt) &&
      now.isBefore(expiresAt) &&
      now.difference(startsAt) < const Duration(hours: 24);

  static List<FairNotification> parse(String body) {
    final data = jsonDecode(body);
    final rows = data is Map ? data['values'] : null;
    if (rows is! List) throw const FormatException('Missing values array');
    if (rows.isEmpty) return [];
    if (rows.first is! List) throw const FormatException('Missing headers');
    final headers =
        (rows.first as List).map((v) => v.toString().trim()).toList();
    const required = [
      'id',
      'title',
      'body',
      'starts_at',
      'expires_at',
      'enabled'
    ];
    if (!required.every(headers.contains) ||
        headers.toSet().length != headers.length) {
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
      if (id.isEmpty ||
          cell('title').isEmpty ||
          cell('body').isEmpty ||
          start == null ||
          end == null ||
          !end.isAfter(start)) {
        continue;
      }
      result.add(FairNotification(id, cell('title'), cell('body'), start, end));
    }
    return result.where((n) => !duplicates.contains(n.id)).toList()
      ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
  }
}

/// Foreground-only polling. Content is never cached or replayed offline.
class FairNotificationService extends ChangeNotifier {
  FairNotificationService(
      {required this.endpoint,
      required this.apiKey,
      required this.preferences,
      http.Client? client,
      DateTime Function()? now})
      : _client = client ?? http.Client(),
        _now = now ?? DateTime.now;

  final String endpoint, apiKey;
  final SharedPreferences preferences;
  final http.Client _client;
  final DateTime Function() _now;
  static const interval = Duration(minutes: 5);
  String get _seenKey => 'notifications_seen_v1:$endpoint';
  String get _nextKey => 'notifications_next_v1:$endpoint';
  Timer? _pollTimer, _expiryTimer;
  bool _active = false, _disposed = false, _busy = false;
  int _failures = 0;
  FairNotification? current;

  Future<void> setActive(bool active) async {
    _active = active;
    _pollTimer?.cancel();
    if (!active) {
      dismiss();
    } else {
      await poll();
    }
  }

  void dismiss() {
    _expiryTimer?.cancel();
    current = null;
    if (!_disposed) notifyListeners();
  }

  Future<void> poll() async {
    final uri = Uri.tryParse(endpoint);
    if (!_active ||
        _disposed ||
        _busy ||
        uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        apiKey.isEmpty) {
      return;
    }
    final next =
        DateTime.fromMillisecondsSinceEpoch(preferences.getInt(_nextKey) ?? 0);
    if (_now().isBefore(next)) {
      _schedule(next.difference(_now()));
      return;
    }
    _busy = true;
    var delay = interval;
    try {
      // Persist throttling so rapid app restarts cannot hammer the API.
      if (!await preferences.setInt(
          _nextKey, _now().add(delay).millisecondsSinceEpoch)) {
        return;
      }
      final response = await _client.get(uri, headers: {
        'x-api-key': apiKey,
        'Cache-Control': 'no-cache',
      }).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        final seconds = int.tryParse(response.headers['retry-after'] ?? '');
        if (seconds != null && seconds > delay.inSeconds) {
          delay = Duration(seconds: seconds);
        }
        throw const FormatException('Notification request failed');
      }
      final notifications = FairNotification.parse(response.body);
      _failures = 0;
      if (!_active || _disposed || current != null) return;
      final seen = (preferences.getStringList(_seenKey) ?? []).toSet();
      for (final notification in notifications) {
        if (!notification.isCurrent(_now()) || seen.contains(notification.id)) {
          continue;
        }
        // Persist before presentation, favouring no repeats after a crash.
        if (!await preferences
            .setStringList(_seenKey, [...seen, notification.id])) {
          return;
        }
        if (!_active || _disposed || !notification.isCurrent(_now())) return;
        current = notification;
        final maxEnd = notification.startsAt.add(const Duration(hours: 24));
        final end = notification.expiresAt.isBefore(maxEnd)
            ? notification.expiresAt
            : maxEnd;
        _expiryTimer = Timer(end.difference(_now()), dismiss);
        notifyListeners();
        break; // At most one banner per poll; no burst of queued messages.
      }
    } catch (_) {
      _failures = (_failures + 1).clamp(1, 4);
      final backoff = Duration(minutes: (5 * (1 << _failures)).clamp(5, 60));
      if (backoff > delay) delay = backoff;
      // Network, malformed data and storage failures must not disrupt the fair.
    } finally {
      if (!_disposed) {
        try {
          await preferences.setInt(
              _nextKey, _now().add(delay).millisecondsSinceEpoch);
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
    if (_active && !_disposed) _pollTimer = Timer(delay, poll);
  }

  @override
  void dispose() {
    _disposed = true;
    _pollTimer?.cancel();
    _expiryTimer?.cancel();
    _client.close();
    super.dispose();
  }
}

class FairNotificationHost extends StatefulWidget {
  const FairNotificationHost(
      {super.key, required this.service, required this.child});
  final FairNotificationService service;
  final Widget child;

  @override
  State<FairNotificationHost> createState() => _FairNotificationHostState();
}

class _FairNotificationHostState extends State<FairNotificationHost>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.service.setActive(WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      widget.service.setActive(state == AppLifecycleState.resumed);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.service,
        builder: (context, _) {
          final notification = widget.service.current;
          return Column(children: [
            if (notification != null)
              Material(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: SafeArea(
                    bottom: false,
                    child: Semantics(
                      liveRegion: true,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                            maxHeight: MediaQuery.sizeOf(context).height * 0.4),
                        child: SingleChildScrollView(
                            child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(notification.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium),
                                      const SizedBox(height: 4),
                                      Text(notification.body),
                                    ])),
                                TextButton(
                                    onPressed: widget.service.dismiss,
                                    child: const Text('Dismiss')),
                              ]),
                        )),
                      ),
                    )),
              ),
            Expanded(child: widget.child),
          ]);
        },
      );
}
