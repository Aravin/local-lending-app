/// Why the borrower is requesting a loan.
enum LoanPurpose {
  business,
  personal,
  emergency,
  education;

  String get label {
    return switch (this) {
      LoanPurpose.business => 'Business',
      LoanPurpose.personal => 'Personal',
      LoanPurpose.emergency => 'Emergency',
      LoanPurpose.education => 'Education',
    };
  }

  String get description {
    return switch (this) {
      LoanPurpose.business => 'Working capital, inventory, or shop expenses',
      LoanPurpose.personal => 'Household needs and planned personal expenses',
      LoanPurpose.emergency => 'Urgent medical or unexpected family costs',
      LoanPurpose.education => 'School fees, courses, or skill training',
    };
  }
}
