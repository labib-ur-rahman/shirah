/**
 * SHIRAH Cloud Functions - Payment Module
 * Handles UddoktaPay payment transaction creation, history, admin approval,
 * and webhook (IPN) processing for auto-approving pending payments.
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
    webhookURL: string;
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
        webhookURL: activeEnv.webhookURL || "",
        verificationPriceBDT: config.verification.priceBDT,
        subscriptionPriceBDT: config.subscription.priceBDT,
      },
    };
  }
);

/**
 * Cloud Function: Re-verify a pending payment against UddoktaPay API.
 *
 * Called from Flutter when user wants to check if their pending payment
 * has been approved. This calls UddoktaPay's verify-payment API server-side
 * and auto-processes the payment if status changed to COMPLETED.
 *
 * Flow:
 * 1. Find the payment transaction in Firestore
 * 2. Call UddoktaPay verify-payment API with the invoiceId
 * 3. If UddoktaPay says COMPLETED → update Firestore + process verification/subscription
 * 4. Return the updated status
 */
export const reVerifyPendingPayment = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<{
    paymentTransactionId: string;
  }>): Promise<ApiResponse<{ status: string; verified?: boolean; subscribed?: boolean }>> => {
    const uid = validateAuthenticated(request.auth);
    const { paymentTransactionId } = request.data;

    if (!paymentTransactionId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Payment transaction ID is required"
      );
    }

    // Get the payment transaction
    const paymentRef = db.collection(COLLECTIONS.PAYMENT_TRANSACTIONS).doc(paymentTransactionId);
    const paymentDoc = await paymentRef.get();

    if (!paymentDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Payment transaction not found");
    }

    const paymentData = paymentDoc.data() as PaymentTransaction;

    // Only the payment owner can re-verify
    if (paymentData.uid !== uid) {
      throw new functions.https.HttpsError("permission-denied", "Not your payment");
    }

    // Skip if already completed
    if (paymentData.status === PAYMENT_STATUS.COMPLETED) {
      return {
        success: true,
        message: "Payment is already completed",
        data: { status: PAYMENT_STATUS.COMPLETED },
      };
    }

    // Only re-verify pending payments
    if (paymentData.status !== PAYMENT_STATUS.PENDING) {
      return {
        success: false,
        message: `Payment is ${paymentData.status}. Only pending payments can be re-verified.`,
        data: { status: paymentData.status },
      };
    }

    // Get UddoktaPay config for API call
    const config = await getAppConfig();
    const activeEnv = config.uddoktaPay.isSandbox
      ? config.uddoktaPay.sandbox
      : config.uddoktaPay.production;

    if (!activeEnv.apiKey || !activeEnv.panelURL) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "UddoktaPay configuration is incomplete"
      );
    }

    // Call UddoktaPay verify-payment API
    const panelURL = activeEnv.panelURL.replace(/\/+$/, "");
    const verifyURL = `${panelURL}/api/verify-payment`;

    functions.logger.info("Re-verifying payment with UddoktaPay", {
      invoiceId: paymentData.invoiceId,
      verifyURL,
    });

    const response = await fetch(verifyURL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "RT-UDDOKTAPAY-API-KEY": activeEnv.apiKey,
      },
      body: JSON.stringify({ invoice_id: paymentData.invoiceId }),
    });

    if (!response.ok) {
      const errorBody = await response.text();
      functions.logger.error("UddoktaPay verify API error", {
        status: response.status,
        body: errorBody,
      });
      throw new functions.https.HttpsError(
        "unavailable",
        `UddoktaPay API returned ${response.status}`
      );
    }

    const verifyData = await response.json() as Record<string, unknown>;
    const uddoktapayStatus = (verifyData.status as string || "").toLowerCase();

    functions.logger.info("UddoktaPay verify response", {
      invoiceId: paymentData.invoiceId,
      status: uddoktapayStatus,
      transactionId: verifyData.transaction_id,
    });

    // Map UddoktaPay status
    let newStatus: string;
    switch (uddoktapayStatus) {
      case "completed":
        newStatus = PAYMENT_STATUS.COMPLETED;
        break;
      case "pending":
        newStatus = PAYMENT_STATUS.PENDING;
        break;
      default:
        newStatus = PAYMENT_STATUS.FAILED;
    }

    // If still pending, just return
    if (newStatus === PAYMENT_STATUS.PENDING) {
      return {
        success: true,
        message: "Payment is still pending. Please wait for approval.",
        data: { status: PAYMENT_STATUS.PENDING },
      };
    }

    // If completed, auto-process!
    let verified = false;
    let subscribed = false;

    if (newStatus === PAYMENT_STATUS.COMPLETED) {
      // Update payment document
      await paymentRef.update({
        status: PAYMENT_STATUS.COMPLETED,
        processedBy: "re-verify",
        processedAt: serverTimestamp(),
        uddoktapayVerifyResponse: verifyData,
        updatedAt: serverTimestamp(),
      });

      // Process verification/subscription
      if (paymentData.type === PAYMENT_TYPES.VERIFICATION) {
        await processVerification(uid, paymentTransactionId);
        verified = true;
      } else if (paymentData.type === PAYMENT_TYPES.SUBSCRIPTION) {
        await processSubscription(uid, paymentTransactionId);
        subscribed = true;
      }

      await createAuditLog({
        actorUid: uid,
        actorRole: "user",
        action: AUDIT_ACTIONS.PAYMENT_ADMIN_APPROVED,
        targetUid: uid,
        metadata: {
          paymentTransactionId,
          type: paymentData.type,
          invoiceId: paymentData.invoiceId,
          approvedVia: "re-verify",
        },
      });

      return {
        success: true,
        message: `Payment completed! ${paymentData.type === PAYMENT_TYPES.VERIFICATION ? "Profile verified!" : "Subscription activated!"}`,
        data: { status: PAYMENT_STATUS.COMPLETED, verified, subscribed },
      };
    }

    // If failed or other status
    await paymentRef.update({
      status: newStatus,
      updatedAt: serverTimestamp(),
    });

    return {
      success: false,
      message: `Payment status is ${newStatus}`,
      data: { status: newStatus },
    };
  }
);

/**
 * Cloud Function (HTTP): UddoktaPay Webhook (IPN) Handler
 *
 * Receives POST requests from UddoktaPay when admin clicks
 * "SEND WEBHOOK REQUEST" in the UddoktaPay dashboard.
 *
 * This auto-approves pending payments and processes verification/subscription
 * without requiring manual approval in the SHIRAH admin panel.
 *
 * Webhook payload (from UddoktaPay docs):
 * {
 *   "full_name": "John Doe",
 *   "email": "user@email.com",
 *   "amount": "100.00",
 *   "fee": "0.00",
 *   "charged_amount": "100.00",
 *   "invoice_id": "Erm9wzjM0FBwjSYT0QVb",
 *   "metadata": { "payment_type": "verification", "uid": "abc123" },
 *   "payment_method": "bkash",
 *   "sender_number": "01311111111",
 *   "transaction_id": "TESTTRANS1",
 *   "date": "2023-01-07 14:00:50",
 *   "status": "COMPLETED"
 * }
 *
 * Security: Validates the RT-UDDOKTAPAY-API-KEY header against stored API key.
 */
export const uddoktapayWebhook = functions.https.onRequest(
  { region: REGION, cors: false },
  async (req, res) => {
    // Only accept POST requests
    if (req.method !== "POST") {
      res.status(405).json({ status: false, message: "Method not allowed" });
      return;
    }

    try {
      // --- 1. Validate API key ---
      const headerApiKey = req.headers["rt-uddoktapay-api-key"] as string | undefined;
      if (!headerApiKey) {
        functions.logger.warn("Webhook: Missing API key header");
        res.status(401).json({ status: false, message: "Unauthorized: Missing API key" });
        return;
      }

      const config = await getAppConfig();
      const activeEnv = config.uddoktaPay.isSandbox
        ? config.uddoktaPay.sandbox
        : config.uddoktaPay.production;

      if (headerApiKey !== activeEnv.apiKey) {
        functions.logger.warn("Webhook: Invalid API key", { received: headerApiKey.substring(0, 8) + "..." });
        res.status(401).json({ status: false, message: "Unauthorized: Invalid API key" });
        return;
      }

      // --- 2. Parse webhook data ---
      const webhookData = req.body;
      const invoiceId: string = webhookData?.invoice_id;
      const webhookStatus: string = webhookData?.status;

      if (!invoiceId) {
        functions.logger.warn("Webhook: Missing invoice_id", { body: webhookData });
        res.status(400).json({ status: false, message: "Missing invoice_id" });
        return;
      }

      functions.logger.info("Webhook received", {
        invoiceId,
        status: webhookStatus,
        paymentMethod: webhookData?.payment_method,
        amount: webhookData?.amount,
      });

      // --- 3. Find existing payment transaction ---
      const existingPayments = await db
        .collection(COLLECTIONS.PAYMENT_TRANSACTIONS)
        .where("invoiceId", "==", invoiceId)
        .limit(1)
        .get();

      if (existingPayments.empty) {
        // Payment not found in our system — might not have been recorded yet.
        // This can happen if webhook arrives before the app sends createPaymentTransaction.
        functions.logger.warn("Webhook: Payment not found for invoiceId", { invoiceId });
        res.status(404).json({ status: false, message: "Payment not found" });
        return;
      }

      const paymentDoc = existingPayments.docs[0];
      const paymentData = paymentDoc.data() as PaymentTransaction;
      const paymentRef = paymentDoc.ref;

      // --- 4. Map webhook status ---
      let newStatus: string;
      switch (webhookStatus?.toLowerCase()) {
        case "completed":
          newStatus = PAYMENT_STATUS.COMPLETED;
          break;
        case "pending":
          newStatus = PAYMENT_STATUS.PENDING;
          break;
        case "canceled":
        case "cancelled":
          newStatus = PAYMENT_STATUS.CANCELED;
          break;
        default:
          newStatus = PAYMENT_STATUS.FAILED;
      }

      // --- 5. Skip if status hasn't improved ---
      // Only process if transitioning from PENDING → COMPLETED
      if (paymentData.status === PAYMENT_STATUS.COMPLETED) {
        functions.logger.info("Webhook: Payment already completed, skipping", { invoiceId });
        res.status(200).json({ status: true, message: "Payment already completed" });
        return;
      }

      if (newStatus !== PAYMENT_STATUS.COMPLETED) {
        // Webhook arrived but status is not COMPLETED — just update metadata
        functions.logger.info("Webhook: Non-completion status update", { invoiceId, newStatus });
        await paymentRef.update({
          status: newStatus,
          "webhookData": webhookData,
          updatedAt: serverTimestamp(),
        });
        res.status(200).json({ status: true, message: `Payment status updated to ${newStatus}` });
        return;
      }

      // --- 6. Auto-approve: PENDING → COMPLETED ---
      functions.logger.info("Webhook: Auto-approving pending payment", {
        invoiceId,
        uid: paymentData.uid,
        type: paymentData.type,
      });

      // Update payment document
      await paymentRef.update({
        status: PAYMENT_STATUS.COMPLETED,
        processedBy: "webhook",
        processedAt: serverTimestamp(),
        "webhookData": webhookData,
        updatedAt: serverTimestamp(),
      });

      // Process verification/subscription
      const paymentUid = paymentData.uid;
      if (paymentData.type === PAYMENT_TYPES.VERIFICATION) {
        await processVerification(paymentUid, paymentDoc.id);
      } else if (paymentData.type === PAYMENT_TYPES.SUBSCRIPTION) {
        await processSubscription(paymentUid, paymentDoc.id);
      }

      // Audit log
      await createAuditLog({
        actorUid: "system",
        actorRole: "system",
        action: AUDIT_ACTIONS.PAYMENT_ADMIN_APPROVED,
        targetUid: paymentUid,
        metadata: {
          paymentTransactionId: paymentDoc.id,
          type: paymentData.type,
          amount: paymentData.amount,
          invoiceId,
          approvedVia: "uddoktapay_webhook",
        },
      });

      functions.logger.info("Webhook: Payment approved successfully", {
        invoiceId,
        uid: paymentUid,
        type: paymentData.type,
      });

      res.status(200).json({
        status: true,
        message: `Payment approved. ${paymentData.type === PAYMENT_TYPES.VERIFICATION ? "User verified" : "Subscription activated"}.`,
      });
    } catch (error) {
      functions.logger.error("Webhook processing error", { error });
      res.status(500).json({ status: false, message: "Internal server error" });
    }
  }
);
