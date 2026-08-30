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
   - Track application status for pending/reviewed requests.
   - KYC renewal banner when verification is expired or due within 30 days.
   - Recent repayment timeline.
4. **Apply for Loan (4-Step Flow)**:
   - *Step 1*: Purpose (Business, Personal, Emergency, Education).
   - *Step 2*: Loan Amount (₹ Slider or input with min/max validation).
   - *Step 3*: Repayment Frequency (`daily`, `weekly`, `biweekly`, `monthly`), interest rate (12–48% p.a.), and tenure selection.
   - *Step 4*: Schedule preview, breakdown of total interest and EMI, instant submission.
   - After submit, borrower is taken to application status tracking.
5. **Loan Application Status**:
   - List of the signed-in borrower's requests with status chips (Pending, Approved, Rejected, Disbursed, Fund issue).
   - Timeline of Applied → Under review → Decision → Disbursement, plus rejection/counter-offer details.
   - After funds are released, a 2-day window to report "Fund not received". EMI starts from the disbursement date if no issue is reported.
6. **Loan Details & Installment Schedule**:
   - Progress bar (Paid installments / Total).
   - List of all upcoming and settled installments with status chips (Paid, Partial, Overdue, Upcoming).
7. **KYC Verification**:
  - Status tracker (Submitted → Under review → Verified / Rejected).
  - Last completed date and valid-until date (1 year). Borrowers must renew annually.
8. **Repayment History**:
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
   - After approval, **Release funds** marks the loan disbursed. Borrower then has 2 days to report a fund issue; EMI starts from the disbursement date otherwise.
4. **KYC Review**:
   - Queue of submitted KYC packs. Approve or reject with a reason.
   - Last completed date and annual expiry / renewal-due filter.
5. **Reports & Insights**:
   - Visual charts (fl_chart) for loan disbursement trends, delinquency aging buckets (1-7 days, 8-30 days, 30+ days).
   - Export report to PDF / CSV.
