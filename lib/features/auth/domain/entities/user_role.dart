/// Role types for the Local Lending application.
enum UserRole {
  /// Borrower applying for loans, paying EMIs, and viewing their loan ledger.
  client,

  /// Lender / Admin managing loan approvals, collection sheets, and reports.
  admin,
}

extension UserRoleX on UserRole {
  bool get isClient => this == UserRole.client;
  bool get isAdmin => this == UserRole.admin;

  String get displayName {
    switch (this) {
      case UserRole.client:
        return 'Borrower / Client';
      case UserRole.admin:
        return 'Lender / Admin';
    }
  }
}
