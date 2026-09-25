import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mill_road_winter_fair_app/date_time_provider.dart';
import 'package:provider/provider.dart';

extension PumpWithClock on WidgetTester {
  Future<void> pumpWithClock(
    Widget widget, {
    DateTimeProvider dateTimeProvider = const SystemDateTimeProvider(),
  }) {
    return pumpWidget(Provider<DateTimeProvider>.value(
      value: dateTimeProvider,
      child: widget,
    ));
  }
}
