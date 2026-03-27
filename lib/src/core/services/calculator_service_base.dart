library;

/// Base interface for calculator services.
///
/// Services can implement this to advertise a stable name and description.
abstract class CalculatorServiceBase {
  String get serviceName;
  String get serviceDescription;
}
