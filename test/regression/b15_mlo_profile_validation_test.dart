import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/features/settings/presentation/screens/settings_screen.dart';

void main() {
  test('rejects non-numeric NMLS and malformed email', () {
    expect(validateMloProfile(nmls: '12ab', email: ''), isNotNull);
    expect(validateMloProfile(nmls: '', email: 'not-an-email'), isNotNull);
  });
  test('accepts blank and well-formed values', () {
    expect(validateMloProfile(nmls: '', email: ''), isNull);
    expect(validateMloProfile(nmls: '1234567', email: 'jane@acme.com'), isNull);
  });
}
