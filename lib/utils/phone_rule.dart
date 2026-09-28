/// The one place the phone number rules live.
///
/// The register form and [AuthService] both read these, so the field can never
/// accept something the service then rejects. That mismatch was the cause of
/// the "it says 11 is too many but fewer does not work" confusion.
///
/// 11 digits was tried first and was too strict: it blocked students whose
/// local number is shorter. The range below is the safe common denominator
/// across the countries in `kCountries`, and 15 is the E.164 maximum.
class PhoneRule {
  PhoneRule._();

  static const int min = 7;
  static const int max = 15;

  /// How many digits are still needed, or 0 when the number is long enough.
  static int remaining(String digits) {
    final n = digits.length;
    return n >= min ? 0 : min - n;
  }

  static bool isValid(String digits) =>
      digits.length >= min && digits.length <= max;

  /// Returns null when valid, otherwise a message naming the exact shortfall.
  static String? validate(String digits) {
    if (digits.isEmpty) return 'Enter your phone number';
    if (digits.length < min) {
      final n = min - digits.length;
      // Note the braces: `$digits.length` would interpolate the string and
      // then the literal text ".length".
      return 'Add $n more digit${n == 1 ? '' : 's'} (${digits.length}/$min)';
    }
    if (digits.length > max) {
      return 'Number cannot be longer than $max digits';
    }
    return null;
  }

  /// A trimmed hint for the field, e.g. `7 to 15 digits, no country code`.
  static String get hint => '$min to $max digits, without the country code';
}
