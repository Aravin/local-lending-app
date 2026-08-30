const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");

initializeApp();

const db = getFirestore();
const paymentMethods = new Set(["upi", "netBanking", "cash", "bankTransfer"]);

exports.recordRepayment = onCall(
  { region: "asia-south1" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in to record a payment.");
    }

    const {
      loanId,
      amountRupees,
      method,
      notes,
      installmentNumber,
    } = request.data ?? {};
    const amountPaise = Math.round(Number(amountRupees) * 100);
    if (
      typeof loanId !== "string" ||
      loanId.length === 0 ||
      !Number.isSafeInteger(amountPaise) ||
      amountPaise <= 0 ||
      !paymentMethods.has(method)
    ) {
      throw new HttpsError("invalid-argument", "Invalid repayment details.");
    }
    if (
      installmentNumber != null &&
      (!Number.isInteger(installmentNumber) || installmentNumber <= 0)
    ) {
      throw new HttpsError("invalid-argument", "Invalid installment number.");
    }

    const loanRef = db.collection("loans").doc(loanId);
    const repaymentRef = db.collection("repayments").doc();
    return db.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(loanRef);
      if (!snapshot.exists) {
        throw new HttpsError("not-found", `Loan ${loanId} was not found.`);
      }

      const loan = snapshot.data();
      const isAdmin = request.auth.token.admin === true;
      if (!isAdmin && loan.borrowerId !== request.auth.uid) {
        throw new HttpsError(
          "permission-denied",
          "You cannot pay another borrower's loan.",
        );
      }
      if (!Array.isArray(loan.installments)) {
        throw new HttpsError("failed-precondition", "Loan schedule is invalid.");
      }

      const installments = loan.installments.map((item) => ({ ...item }));
      const startIndex =
        installmentNumber == null
          ? installments.findIndex((item) => item.status !== "paid")
          : installments.findIndex(
              (item) => item.installmentNumber === installmentNumber,
            );
      if (startIndex < 0 || installments[startIndex].status === "paid") {
        throw new HttpsError(
          "failed-precondition",
          "The selected installment is already settled.",
        );
      }

      const availablePaise = installments
        .slice(startIndex)
        .filter((item) => item.status !== "paid")
        .reduce(
          (total, item) =>
            total +
            Math.max(
              0,
              Math.round(
                (Number(item.amountRupees) -
                  Number(item.paidAmountRupees ?? 0)) *
                  100,
              ),
            ),
          0,
        );
      if (amountPaise > availablePaise) {
        throw new HttpsError(
          "out-of-range",
          "Payment exceeds the outstanding balance.",
        );
      }

      const paidAt = new Date().toISOString();
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const firstOutstandingPaise = Math.round(
        (Number(installments[startIndex].amountRupees) -
          Number(installments[startIndex].paidAmountRupees ?? 0)) *
          100,
      );
      let remainingPaise = amountPaise;
      for (let index = startIndex; index < installments.length; index += 1) {
        const installment = installments[index];
        if (remainingPaise <= 0 || installment.status === "paid") {
          continue;
        }
        const outstandingPaise = Math.max(
          0,
          Math.round(
            (Number(installment.amountRupees) -
              Number(installment.paidAmountRupees ?? 0)) *
              100,
          ),
        );
        const appliedPaise = Math.min(remainingPaise, outstandingPaise);
        const paidTotalPaise =
          Math.round(Number(installment.paidAmountRupees ?? 0) * 100) +
          appliedPaise;
        installment.paidAmountRupees = paidTotalPaise / 100;
        const settled =
          paidTotalPaise >= Math.round(Number(installment.amountRupees) * 100);
        const dueDate = new Date(installment.dueDate);
        installment.status = settled
          ? "paid"
          : dueDate < today
            ? "overdue"
            : "partial";
        installment.paidDate = paidAt;
        if (typeof notes === "string" && notes.length > 0) {
          installment.notes = notes;
        }
        remainingPaise -= appliedPaise;
      }

      const completed = installments.every((item) => item.status === "paid");
      const overdue = installments.some((item) => item.status === "overdue");
      const repayment = {
        id: repaymentRef.id,
        loanId,
        borrowerId: loan.borrowerId,
        installmentNumber: installments[startIndex].installmentNumber,
        amountRupees: amountPaise / 100,
        method,
        paidAt,
        reference: `FIREBASE-${repaymentRef.id}`,
        isPartial: amountPaise < firstOutstandingPaise,
        notes: typeof notes === "string" ? notes : null,
      };
      transaction.update(loanRef, {
        installments,
        status: completed ? "closed" : overdue ? "overdue" : "active",
        closedDate: completed ? paidAt : loan.closedDate ?? null,
      });
      transaction.set(repaymentRef, repayment);
      return repayment;
    });
  },
);
