/**
 * SHIRAH Cloud Functions - Payment Module
 * Handles UddoktaPay payment transaction creation, history, and admin approval
 */

import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import {
  COLLECTIONS,
  PAYMENT_STATUS,
  PAYMENT_TYPES,
  AUDIT_ACTIONS,
  REGION,
  USER_ROLES,
} from "../../config/constants";
import { getAppConfig } from "../../config/dynamic-config";
import { ApiResponse, PaymentTransaction } from "../../types";
import { serverTimestamp } from "../../utils/helpers";
import {
  validateAuthenticated,
  validateUserAccountState,
  validateMinimumRole,
  validateAdminPermission,
} from "../../utils/validators";
import { createAuditLog } from "../audit/audit-logging";
import { getUserByUid } from "../users/user-management";
import { processVerification, processSubscription } from "../auth/auth-and-verification";
import { getAdminPermissions } from "../permissions/rbac-and-permissions";

const db = admin.firestore();

/**
 * Cloud Function: Create a payment transaction after UddoktaPay response
 * Called from Flutter after UddoktaPay payment completes/cancels/pends
 */
export const createPaymentTransaction = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<{
    type: string;
    uddoktapayResponse: {
      fullName: string;
      email: string;
      amount: string;
      fee: string;
      chargedAmount: string;
      invoiceId: string;
      paymentMethod: string;
      senderNumber: string;
      transactionId: string;
      date: string;
      status: string;
    };
  }>): Promise<ApiResponse<{ paymentTransactionId: string; verified?: boolean; subscribed?: boolean }>> => {
    const uid = validateAuthenticated(request.auth);
    const { type, uddoktapayResponse } = request.data;

    // Validate type
    if (type !== PAYMENT_TYPES.VERIFICATION && type !== PAYMENT_TYPES.SUBSCRIPTION) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Invalid payment type. Must be 'verification' or 'subscription'"
      );
    }

    if (!uddoktapayResponse || !uddoktapayResponse.invoiceId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "UddoktaPay response is required"
      );
    }

    const user = await getUserByUid(uid);
    if (!user) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }

    validateUserAccountState(user.status.accountState);

    // Check if user already has the status they're buying
    if (type === PAYMENT_TYPES.VERIFICATION && user.status.verified) {
      throw new functions.https.HttpsError(
        "already-exists",
        "User is already verified"
      );
    }
    if (type === PAYMENT_TYPES.SUBSCRIPTION && user.status.subscription === "active") {
      throw new functions.https.HttpsError(
        "already-exists",
        "User already has an active subscription"
      );
    }

    // Check for duplicate invoiceId
    const existingPayment = await db
      .collection(COLLECTIONS.PAYMENT_TRANSACTIONS)
      .where("invoiceId", "==", uddoktapayResponse.invoiceId)
      .limit(1)
      .get();

    if (!existingPayment.empty) {
      throw new functions.https.HttpsError(
        "already-exists",
        "This payment has already been recorded"
      );
    }

    // Map UddoktaPay status to our status
    let status: string;
    switch (uddoktapayResponse.status?.toLowerCase()) {
      case "completed":
        status = PAYMENT_STATUS.COMPLETED;
        break;
      case "pending":
        status = PAYMENT_STATUS.PENDING;
        break;
      case "canceled":
      case "cancelled":
        status = PAYMENT_STATUS.CANCELED;
        break;
      default:
        status = PAYMENT_STATUS.FAILED;
    }

    // Create payment transaction document
    const paymentRef = db.collection(COLLECTIONS.PAYMENT_TRANSACTIONS).doc();
    const paymentDoc: Omit<PaymentTransaction, "createdAt" | "updatedAt" | "processedAt"> & {
      createdAt: FirebaseFirestore.FieldValue;
      updatedAt: FirebaseFirestore.FieldValue;
      processedAt: null;
    } = {
      id: paymentRef.id,
      uid,
      type: type as PaymentTransaction["type"],
      amount: parseFloat(uddoktapayResponse.amount) || 0,
      status: status as PaymentTransaction["status"],
      paymentMethod: uddoktapayResponse.paymentMethod || "",
      invoiceId: uddoktapayResponse.invoiceId,
      transactionId: uddoktapayResponse.transactionId || "",
      senderNumber: uddoktapayResponse.senderNumber || "",
      fee: uddoktapayResponse.fee || "0.00",
      chargedAmount: uddoktapayResponse.chargedAmount || "0.00",
      uddoktapayResponse: uddoktapayResponse as unknown as Record<string, unknown>,
      processedBy: null,
      processedAt: null,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    };

    await paymentRef.set(paymentDoc);

    await createAuditLog({
      actorUid: uid,
      actorRole: user.role,
      action: AUDIT_ACTIONS.PAYMENT_CREATED,
      targetUid: uid,
      metadata: {
        paymentTransactionId: paymentRef.id,
        type,
        status,
        invoiceId: uddoktapayResponse.invoiceId,
        amount: uddoktapayResponse.amount,
      },
    });

    // If payment is completed, process verification/subscription immediately
    let verified = false;
    let subscribed = false;

    if (status === PAYMENT_STATUS.COMPLETED) {
      if (type === PAYMENT_TYPES.VERIFICATION) {
        await processVerification(uid, paymentRef.id);
        verified = true;
      } else if (type === PAYMENT_TYPES.SUBSCRIPTION) {
        await processSubscription(uid, paymentRef.id);
        subscribed = true;
      }
    }

    return {
      success: true,
      message: status === PAYMENT_STATUS.COMPLETED
        ? `Payment successful. ${type === PAYMENT_TYPES.VERIFICATION ? "Profile verified!" : "Subscription activated!"}`
        : status === PAYMENT_STATUS.PENDING
          ? "Payment is pending. You will be notified when it's confirmed."
          : "Payment was not completed.",
      data: {
        paymentTransactionId: paymentRef.id,
        verified,
        subscribed,
      },
    };
  }
);

/**
 * Cloud Function: Admin approve a pending payment
 * Used when payment is stuck in pending state
 */
export const adminApprovePayment = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<{
    paymentTransactionId: string;
  }>): Promise<ApiResponse> => {
    const adminUid = validateAuthenticated(request.auth);
    const { paymentTransactionId } = request.data;

    if (!paymentTransactionId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Payment transaction ID is required"
      );
    }

    // Validate admin permission
    const adminUser = await getUserByUid(adminUid);
    if (!adminUser) {
      throw new functions.https.HttpsError("not-found", "Admin user not found");
    }

    // SuperAdmin bypasses permission check
    if (adminUser.role !== USER_ROLES.SUPER_ADMIN) {
      validateMinimumRole(adminUser.role, USER_ROLES.SUPPORT);
      const permissions = await getAdminPermissions(adminUid);
      validateAdminPermission(permissions, "payment.approve");
    }

    // Get the payment transaction
    const paymentRef = db.collection(COLLECTIONS.PAYMENT_TRANSACTIONS).doc(paymentTransactionId);
    const paymentDoc = await paymentRef.get();

    if (!paymentDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Payment transaction not found");
    }

    const paymentData = paymentDoc.data() as PaymentTransaction;

    if (paymentData.status !== PAYMENT_STATUS.PENDING) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        `Payment is already ${paymentData.status}. Only pending payments can be approved.`
      );
    }

    // Update payment status
    await paymentRef.update({
      status: PAYMENT_STATUS.COMPLETED,
      processedBy: adminUid,
      processedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });

    // Process verification/subscription for the user
    const paymentUid = paymentData.uid;
    if (paymentData.type === PAYMENT_TYPES.VERIFICATION) {
      await processVerification(paymentUid, paymentTransactionId);
    } else if (paymentData.type === PAYMENT_TYPES.SUBSCRIPTION) {
      await processSubscription(paymentUid, paymentTransactionId);
    }

    await createAuditLog({
      actorUid: adminUid,
      actorRole: adminUser.role,
      action: AUDIT_ACTIONS.PAYMENT_ADMIN_APPROVED,
      targetUid: paymentUid,
      metadata: {
        paymentTransactionId,
        type: paymentData.type,
        amount: paymentData.amount,
        invoiceId: paymentData.invoiceId,
      },
    });

    return {
      success: true,
      message: `Payment approved. User ${paymentData.type === PAYMENT_TYPES.VERIFICATION ? "verified" : "subscribed"} successfully.`,
    };
  }
);

/**
 * Cloud Function: Get payment history for current user
 */
export const getPaymentHistory = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<{
    limit?: number;
    startAfter?: string;
  }>): Promise<ApiResponse<PaymentTransaction[]>> => {
    const uid = validateAuthenticated(request.auth);
    const limit = request.data?.limit || 20;

    let query = db
      .collection(COLLECTIONS.PAYMENT_TRANSACTIONS)
      .where("uid", "==", uid)
      .orderBy("createdAt", "desc")
      .limit(limit);

    if (request.data?.startAfter) {
      const startAfterDoc = await db
        .collection(COLLECTIONS.PAYMENT_TRANSACTIONS)
        .doc(request.data.startAfter)
        .get();

      if (startAfterDoc.exists) {
        query = query.startAfter(startAfterDoc);
      }
    }

    const snapshot = await query.get();
    const transactions = snapshot.docs.map(
      (doc) => doc.data() as PaymentTransaction
    );

    return {
      success: true,
      message: "Payment history retrieved",
      data: transactions,
    };
  }
);

/**
 * Cloud Function: Get all payment transactions (Admin)
 * For admin panel to review pending payments
 */
export const getAdminPaymentTransactions = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<{
    limit?: number;
    status?: string;
    type?: string;
  }>): Promise<ApiResponse<PaymentTransaction[]>> => {
    const adminUid = validateAuthenticated(request.auth);
    const adminUser = await getUserByUid(adminUid);
    if (!adminUser) {
      throw new functions.https.HttpsError("not-found", "Admin user not found");
    }

    // SuperAdmin bypasses permission check
    if (adminUser.role !== USER_ROLES.SUPER_ADMIN) {
      validateMinimumRole(adminUser.role, USER_ROLES.SUPPORT);
      const permissions = await getAdminPermissions(adminUid);
      validateAdminPermission(permissions, "payment.approve");
    }

    const limit = request.data?.limit || 50;
    let query: FirebaseFirestore.Query = db
      .collection(COLLECTIONS.PAYMENT_TRANSACTIONS)
      .orderBy("createdAt", "desc")
      .limit(limit);

    if (request.data?.status) {
      query = query.where("status", "==", request.data.status);
    }
    if (request.data?.type) {
      query = query.where("type", "==", request.data.type);
    }

    const snapshot = await query.get();
    const transactions = snapshot.docs.map(
      (doc) => doc.data() as PaymentTransaction
    );

    return {
      success: true,
      message: "Payment transactions retrieved",
      data: transactions,
    };
  }
);

/**
 * Cloud Function: Get UddoktaPay configuration for Flutter
 * Returns non-sensitive config needed to initialize UddoktaPay SDK
 */
export const getPaymentConfig = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest): Promise<ApiResponse<{
    isSandbox: boolean;
    apiKey: string;
    panelURL: string;
    redirectURL: string;
    verificationPriceBDT: number;
    subscriptionPriceBDT: number;
  }>> => {
    validateAuthenticated(request.auth);

    const config = await getAppConfig();

    // Select the active environment keys based on isSandbox flag
    const activeEnv = config.uddoktaPay.isSandbox
      ? config.uddoktaPay.sandbox
      : config.uddoktaPay.production;

    return {
      success: true,
      message: "Payment configuration retrieved",
      data: {
        isSandbox: config.uddoktaPay.isSandbox,
        apiKey: activeEnv.apiKey,
        panelURL: activeEnv.panelURL,
        redirectURL: activeEnv.redirectURL,
        verificationPriceBDT: config.verification.priceBDT,
        subscriptionPriceBDT: config.subscription.priceBDT,
      },
    };
  }
);
