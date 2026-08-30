/// How a repayment was collected or initiated.
enum PaymentMethod {
  upi,
  netBanking,
  cash,
  bankTransfer;

  String get label {
    return switch (this) {
      PaymentMethod.upi => 'UPI',
      PaymentMethod.netBanking => 'Net Banking',
      PaymentMethod.cash => 'Cash',
      PaymentMethod.bankTransfer => 'Bank Transfer',
    };
  }
}
