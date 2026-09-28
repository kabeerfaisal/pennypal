import 'package:flutter_test/flutter_test.dart';
import 'package:penny_pal/utils/phone_rule.dart';

void main() {
  group('PhoneRule.validate', () {
    test('an empty field is asked for, not rejected as too short', () {
      expect(PhoneRule.validate(''), 'Enter your phone number');
    });

    test('a short number is told exactly how many digits are missing', () {
      expect(PhoneRule.validate('3'), contains('6 more digits'));
      expect(PhoneRule.validate('0300'), contains('3 more digits'));
    });

    test('the singular is used for exactly one missing digit', () {
      // min is 7, so six digits needs one more and must not say "1 more digits".
      expect(PhoneRule.validate('030012'), contains('1 more digit ('));
      expect(PhoneRule.validate('030012'), isNot(contains('1 more digits')));
    });

    test('a normal number passes with no complaint', () {
      for (final good in const ['03001234567', '0300123', '123456789012345']) {
        expect(PhoneRule.validate(good), isNull, reason: good);
      }
    });

    test('one digit over the maximum is rejected, not silently trimmed', () {
      expect(PhoneRule.validate('1234567890123456'), contains('15'));
    });
  });

  group('PhoneRule bounds', () {
    test('isValid matches validate being null', () {
      for (final n in const [
        '',
        '1',
        '123456',
        '1234567',
        '123456789012345',
        '1234567890123456',
      ]) {
        expect(
          PhoneRule.isValid(n),
          PhoneRule.validate(n) == null,
          reason: 'mismatch for "$n"',
        );
      }
    });

    test('remaining counts down to zero and then stays there', () {
      expect(PhoneRule.remaining(''), PhoneRule.min);
      expect(PhoneRule.remaining('123456'), 1);
      expect(PhoneRule.remaining('1234567'), 0);
      expect(PhoneRule.remaining('123456789012345'), 0);
    });

    test('the maximum is the E.164 limit, not an arbitrary number', () {
      expect(PhoneRule.max, 15);
    });

    test('the hint states the whole range so nothing is hidden', () {
      expect(
        PhoneRule.hint,
        startsWith('${PhoneRule.min} to ${PhoneRule.max} digits'),
      );
      expect(PhoneRule.hint, contains('country code'));
    });
  });

  group('regression: the reported frustration', () {
    test('adding a full 11 digit number is accepted', () {
      // The old form blocked this and told the user it was too long.
      expect(PhoneRule.validate('03001234567'), isNull);
    });

    test('a short local number is accepted instead of blocked', () {
      // The old form demanded exactly 11 and would not let the user register.
      for (final short in const ['0300123', '1234567', '03123456']) {
        expect(PhoneRule.validate(short), isNull, reason: short);
      }
    });

    test('no length is described as "exactly 11" anywhere', () {
      for (final n in const [
        '',
        '1',
        '123456',
        '1234567',
        '1234567890123456',
      ]) {
        expect(PhoneRule.validate(n) ?? '', isNot(contains('exactly 11')));
      }
    });
  });
}
