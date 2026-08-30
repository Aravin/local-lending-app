# Screen Catalog & User Flows

## Borrower Portal

1. **Splash & Onboarding**:
   - Displays client branding, dynamic logo, and punchy value proposition.
   - One-tap Google Sign-In action.
2. **Profile Setup**:
   - Collects 10-digit Indian mobile number, full name, KYC reference, and address.
3. **Borrower Dashboard**:
   - Summary cards: Total active loans, next payment due amount and countdown.
   - Quick action: "Apply for Loan".
   - Recent repayment timeline.
4. **Apply for Loan (4-Step Flow)**:
   - *Step 1*: Purpose (Business, Personal, Emergency, Education).
   - *Step 2*: Loan Amount (₹ Slider or input with min/max validation).
   - *Step 3*: Repayment Frequency (`daily`, `weekly`, `biweekly`, `monthly`) & Tenure selection.
   - *Step 4*: Schedule preview, breakdown of total interest and EMI, instant submission.
5. **Loan Details & Installment Schedule**:
   - Progress bar (Paid installments / Total).
   - List of all upcoming and settled installments with status chips (Paid, Partial, Overdue, Upcoming).
6. **Repayment History**:
   - Filterable transaction logs by frequency type and status.

## Lender & Admin Console

1. **Admin Dashboard**:
   - Portfolio metrics: Total Capital Disbursed, Total Collected, Total Outstanding, Overdue Risk Ratio.
   - Breakdown by frequency type (Daily vs Weekly vs Monthly).
2. **Collection Sheet (Daily Dues)**:
   - Grouped list of all borrowers with payments due today.
   - Quick mark-as-paid or partial payment logging.
3. **Loan Application Approvals**:
   - Application queue, applicant profile, credit score and underwriting metrics.
   - Approve, Reject with reason, or Counter-offer.
4. **Reports & Insights**:
   - Visual charts (fl_chart) for loan disbursement trends, delinquency aging buckets (1-7 days, 8-30 days, 30+ days).
   - Export report to PDF / CSV.
