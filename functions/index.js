const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getStorage } = require("firebase-admin/storage");

initializeApp();

const db = getFirestore();
const kycBucket = getStorage().bucket("cape-finance-kyc-265372728533");
const paymentMethods = new Set(["upi", "netBanking", "cash", "bankTransfer"]);

exports.recordRepayment = onCall(
  { region: "asia-south1" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in to record a payment.");
    }
    if (request.auth.token.admin !== true) {
      throw new HttpsError(
        "permission-denied",
        "Only an administrator can confirm received payments.",
      );
    }

    const {
      loanId,
      amountRupees,
      method,
      notes,
      installmentNumber,
      idempotencyKey,
    } = request.data ?? {};
    const amountPaise = Math.round(Number(amountRupees) * 100);
    if (
      typeof loanId !== "string" ||
      loanId.length === 0 ||
      !Number.isSafeInteger(amountPaise) ||
      amountPaise <= 0 ||
      !paymentMethods.has(method) ||
      typeof idempotencyKey !== "string" ||
      !/^[A-Za-z0-9_-]{1,128}$/.test(idempotencyKey)
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
    const repaymentRef = db.collection("repayments").doc(idempotencyKey);
    return db.runTransaction(async (transaction) => {
      const existingRepayment = await transaction.get(repaymentRef);
      if (existingRepayment.exists) {
        return existingRepayment.data();
      }
      const snapshot = await transaction.get(loanRef);
      if (!snapshot.exists) {
        throw new HttpsError("not-found", `Loan ${loanId} was not found.`);
      }

      const loan = snapshot.data();
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

function isKycDocumentPath(path, userId, documentType) {
  if (typeof path !== "string") {
    return false;
  }
  const prefix = `kyc/${userId}/${documentType}-`;
  const fileName = path.slice(prefix.length);
  return path.startsWith(prefix) && /^[0-9]+[.][a-z0-9]+$/.test(fileName);
}

async function verifyKycDocument(path) {
  const file = kycBucket.file(path);
  const [exists] = await file.exists();
  if (!exists) {
    throw new HttpsError(
      "failed-precondition",
      "Both KYC documents must be uploaded before submission.",
    );
  }
  const [metadata] = await file.getMetadata();
  const size = Number(metadata.size);
  if (
    !Number.isFinite(size) ||
    size <= 0 ||
    size >= 10 * 1024 * 1024 ||
    !metadata.contentType?.startsWith("image/")
  ) {
    throw new HttpsError("failed-precondition", "Invalid KYC document.");
  }
}

exports.submitKyc = onCall(
  { region: "asia-south1" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in to submit KYC.");
    }

    const {
      fullName,
      aadhaarNumber,
      panNumber,
      address,
      idProofPath,
      addressProofPath,
    } = request.data ?? {};
    const userId = request.auth.uid;
    if (
      typeof fullName !== "string" ||
      fullName.trim().length < 2 ||
      typeof aadhaarNumber !== "string" ||
      !/^[0-9]{12}$/.test(aadhaarNumber) ||
      typeof panNumber !== "string" ||
      !/^[A-Z]{5}[0-9]{4}[A-Z]$/.test(panNumber) ||
      typeof address !== "string" ||
      address.trim().length === 0 ||
      !isKycDocumentPath(idProofPath, userId, "identity") ||
      !isKycDocumentPath(addressProofPath, userId, "address")
    ) {
      throw new HttpsError("invalid-argument", "Invalid KYC details.");
    }

    await Promise.all([
      verifyKycDocument(idProofPath),
      verifyKycDocument(addressProofPath),
    ]);

    const kycRef = db.collection("kyc").doc(userId);
    const customerRef = db.collection("customers").doc(userId);
    const submitted = await db.runTransaction(async (transaction) => {
      const currentSnapshot = await transaction.get(kycRef);
      const customerSnapshot = await transaction.get(customerRef);
      const current = currentSnapshot.data();
      const now = new Date();
      if (current?.status === "submitted") {
        throw new HttpsError(
          "failed-precondition",
          "This KYC submission is already under review.",
        );
      }
      if (current?.status === "verified") {
        const verifiedAt = new Date(current.verifiedAt);
        if (Number.isNaN(verifiedAt.getTime())) {
          throw new HttpsError(
            "failed-precondition",
            "The existing KYC verification date is invalid.",
          );
        }
        const renewalOpensAt = new Date(verifiedAt);
        renewalOpensAt.setFullYear(renewalOpensAt.getFullYear() + 1);
        renewalOpensAt.setDate(renewalOpensAt.getDate() - 30);
        if (now < renewalOpensAt) {
          throw new HttpsError(
            "failed-precondition",
            "KYC renewal is not due yet.",
          );
        }
      }
      const profile = {
        userId,
        fullName: fullName.trim(),
        aadhaarNumber,
        panNumber,
        address: address.trim(),
        idProofUploaded: true,
        addressProofUploaded: true,
        idProofPath,
        addressProofPath,
        submittedAt: now.toISOString(),
        verifiedAt: current?.verifiedAt ?? null,
        rejectionReason: null,
        status: "submitted",
      };
      transaction.set(kycRef, profile);
      transaction.set(
        customerRef,
        customerSnapshot.exists
          ? { kycStatus: "submitted" }
          : {
              id: userId,
              name: fullName.trim(),
              phone: "",
              email: "",
              activeLoansCount: 0,
              lifetimeRepaymentRate: 1,
              riskTier: "low",
              kycStatus: "submitted",
              outstandingRupees: 0,
              address: address.trim(),
            },
        { merge: true },
      );
      return profile;
    });
    return submitted;
  },
);
