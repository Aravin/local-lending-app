/// Common form and domain validators used across loan applications,
/// profile setups, and admin actions.
class Validators {
  Validators._();

  /// Validates an Indian phone number (10 digits, optionally starting with +91 or 0).
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final cleaned = value.replaceAll(RegExp(r'[\s\-()]'), '');
    final regex = RegExp(r'^(?:\+91|0)?[6-9]\d{9}$');
    if (!regex.hasMatch(cleaned)) {
      return 'Enter a valid 10-digit Indian phone number';
    }
    return null;
  }

  /// Validates a borrower/user full name.
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (!RegExp(r"^[a-zA-Z\s\.'\-]+$").hasMatch(value.trim())) {
      return 'Name contains invalid characters';
    }
    return null;
  }

  /// Validates loan amount against configured limits.
  static String? validateLoanAmount({
    required String? value,
    required double minAmount,
    required double maxAmount,
  }) {
    if (value == null || value.trim().isEmpty) {
      return 'Loan amount is required';
    }
    final amount = double.tryParse(value.replaceAll(',', '').trim());
    if (amount == null) {
      return 'Enter a valid amount';
    }
    if (amount < minAmount) {
      return 'Amount must be at least ₹${minAmount.toStringAsFixed(0)}';
    }
    if (amount > maxAmount) {
      return 'Amount cannot exceed ₹${maxAmount.toStringAsFixed(0)}';
    }
    return null;
  }

  /// Validates a 12-digit Aadhaar number.
  static String? validateAadhaar(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Aadhaar number is required';
    }
    final cleaned = value.replaceAll(RegExp(r'\s|-'), '');
    if (!RegExp(r'^\d{12}$').hasMatch(cleaned)) {
      return 'Enter a valid 12-digit Aadhaar number';
    }
    return null;
  }

  /// Validates a PAN in ABCDE1234F format.
  static String? validatePan(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'PAN is required';
    }
    if (!RegExp(
      r'^[A-Z]{5}[0-9]{4}[A-Z]$',
    ).hasMatch(value.trim().toUpperCase())) {
      return 'Enter a valid PAN (ABCDE1234F)';
    }
    return null;
  }

  /// Validates tenure for a specific frequency.
  static String? validateTenure({
    required String? value,
    required int minTenure,
    required int maxTenure,
    required String unit,
  }) {
    if (value == null || value.trim().isEmpty) {
      return 'Tenure is required';
    }
    final tenure = int.tryParse(value.trim());
    if (tenure == null) {
      return 'Enter a valid integer';
    }
    if (tenure < minTenure || tenure > maxTenure) {
      return 'Tenure must be between $minTenure and $maxTenure $unit';
    }
    return null;
  }
}
