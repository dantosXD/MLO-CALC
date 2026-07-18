import 'package:flutter_test/flutter_test.dart';
import 'package:loan_ranger/src/core/utils/type_utils.dart';

void main() {
  group('TypeUtils.toDouble', () {
    test('converts double', () => expect(TypeUtils.toDouble(3.14), 3.14));
    test('converts int', () => expect(TypeUtils.toDouble(5), 5.0));
    test('converts num', () {
      num n = 7;
      expect(TypeUtils.toDouble(n), 7.0);
    });
    test('parses valid string', () => expect(TypeUtils.toDouble('2.5'), 2.5));
    test(
      'returns null for invalid string',
      () => expect(TypeUtils.toDouble('abc'), isNull),
    );
    test(
      'returns null for null',
      () => expect(TypeUtils.toDouble(null), isNull),
    );
    test(
      'returns null for List',
      () => expect(TypeUtils.toDouble([1, 2]), isNull),
    );
  });
}
