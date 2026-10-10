// Define an interface for providing date and time functionality
abstract interface class DateTimeProvider {
  DateTime now();
}

// A Date/Time provider for use in production code
final class SystemDateTimeProvider implements DateTimeProvider {
  const SystemDateTimeProvider();

  @override
  DateTime now() => DateTime.now();
}
