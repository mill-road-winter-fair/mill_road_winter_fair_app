import 'package:mill_road_winter_fair_app/date_time_provider.dart';

// A Date/Time provider for use in tests
final class FixedDateTimeProvider implements DateTimeProvider {
  final DateTime value;

  const FixedDateTimeProvider(this.value);

  @override
  DateTime now() => value;
}
