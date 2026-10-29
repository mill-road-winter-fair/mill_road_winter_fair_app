import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mill_road_winter_fair_app/helpers.dart';

void main() {
  test('backs off for 250ms then 500ms before retrying', () async {
    final elapsed = Stopwatch()..start();
    final starts = <Duration>[];
    final route = await requestRoute(() async {
      starts.add(elapsed.elapsed);
      if (starts.length < 3) throw const SocketException('Connection lost');
      return 'route';
    });
    expect(route, 'route');
    expect(starts, hasLength(3));
    expect(starts[1] - starts[0], greaterThanOrEqualTo(const Duration(milliseconds: 250)));
    expect(starts[2] - starts[1], greaterThanOrEqualTo(const Duration(milliseconds: 500)));
  });

  test('does not retry when backoff would exhaust the budget', () async {
    var attempts = 0;
    await expectLater(
      requestRoute(
        () async {
          attempts++;
          throw const SocketException('Connection lost');
        },
        timeout: const Duration(milliseconds: 100),
      ),
      throwsA(isA<TimeoutException>()),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(attempts, 1);
  });

  test('does not start a request when the budget is exhausted', () async {
    var attempts = 0;
    await expectLater(
      requestRoute(
        () async {
          attempts++;
          return 'route';
        },
        timeout: Duration.zero,
      ),
      throwsA(isA<TimeoutException>()),
    );
    expect(attempts, 0);
  });

  test('deadline ends a stalled attempt and late failure cannot trigger a retry', () async {
    var attempts = 0;
    final pending = Completer<String>();
    await expectLater(
      requestRoute(
        () {
          attempts++;
          return pending.future;
        },
        timeout: const Duration(milliseconds: 50),
      ),
      throwsA(isA<TimeoutException>()),
    );
    expect(attempts, 1);
    pending.completeError(const SocketException('Late failure'));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(attempts, 1);
  });

  test('second attempt uses only the remaining budget and ignores late success', () async {
    final pending = <Completer<String>>[];
    final elapsed = Stopwatch()..start();
    await expectLater(
      requestRoute(
        () {
          final attempt = Completer<String>();
          pending.add(attempt);
          return attempt.future;
        },
        timeout: const Duration(milliseconds: 3600),
      ),
      throwsA(isA<TimeoutException>()),
    );
    expect(pending, hasLength(2));
    // Allow scheduling headroom, but not a fresh three-second second attempt.
    expect(elapsed.elapsed, lessThan(const Duration(seconds: 5)));
    for (final attempt in pending) {
      attempt.complete('late route');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(pending, hasLength(2));
  });

  for (final failure in <Exception>[
    TimeoutException('Request stalled'),
    const SocketException('Connection lost'),
  ]) {
    test('retries ${failure.runtimeType} and returns the successful route', () async {
      var attempts = 0;
      final route = await requestRoute(() async {
        if (++attempts == 1) throw failure;
        return 'route';
      });
      expect(route, 'route');
      expect(attempts, 2);
    });

    test('stops retrying ${failure.runtimeType} at maxAttempts', () async {
      var attempts = 0;
      await expectLater(
        requestRoute(
          () async {
            attempts++;
            throw failure;
          },
          maxAttempts: 2,
        ),
        throwsA(same(failure)),
      );
      expect(attempts, 2);
    });
  }

  for (final failure in <Object>[
    const FormatException('Malformed or empty route'),
    const HttpException('Network error: FormatException: Invalid JSON'),
    const HttpException('Unauthorised request'),
    Exception('API failure'),
    ArgumentError('Invalid destination'),
  ]) {
    test('propagates $failure without retrying', () async {
      var attempts = 0;
      await expectLater(
        requestRoute(() async {
          attempts++;
          throw failure;
        }),
        throwsA(same(failure)),
      );
      expect(attempts, 1);
    });
  }
}
