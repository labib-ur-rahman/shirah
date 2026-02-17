/**
 * SHIRAH Cloud Functions - Mobile Recharge & Drive Offer Module
 * ================================================================
 * Handles mobile recharge, drive offer purchases, status polling,
 * offer caching, and admin operations via ECARE Technology API.
 *
 * Google Play Policy: This is a real-world service (telecom top-up),
 * NOT a digital good. Google Play billing is NOT required.
 */

import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { defineSecret } from "firebase-functions/params";
import {
  COLLECTIONS,
  TRANSACTION_TYPES,
  TRANSACTION_SOURCES,
  AUDIT_ACTIONS,
  REGION,
  USER_ROLES,
  RECHARGE_TYPES,
  RECHARGE_STATUS,
  OPERATOR_MAP,
  OFFER_TO_RECHARGE_MAP,
  NUMBER_TYPE_MAP,
  OFFER_TYPE_MAP,
  ECARE_CONFIG,
} from "../../config/constants";
import {
  ApiResponse,
  MobileRechargeDocument,
  DriveOfferItem,
  DriveOfferCacheDocument,
  InitiateRechargeRequest,
  GetDriveOffersRequest,
  GetRechargeHistoryRequest,
  EcareRechargeResponse,
  EcareStatusResponse,
  EcareBalanceResponse,
  EcareOfferPackResponse,
  RawEcareOffer,
  UserDocument,
} from "../../types";
import {
  serverTimestamp,
  generateTransactionId,
  sleep,
  isValidPhoneNumber,
} from "../../utils/helpers";
import {
  validateAuthenticated,
  validateMinimumRole,
} from "../../utils/validators";
import { createAuditLog } from "../audit/audit-logging";
import { getUserByUid } from "../users/user-management";

const db = admin.firestore();

// ============================================
// FIREBASE SECRETS
// ============================================

const ecareAccessId = defineSecret("ECARE_ACCESS_ID");
const ecareAccessPass = defineSecret("ECARE_ACCESS_PASS");

// ============================================
// ECARE API HELPERS
// ============================================

/**
 * Get ECARE API credentials from Firebase environment config
 * Supports process.env variables (set via Firebase secrets or .env file)
 */
function getEcareCredentials(): { accessId: string; accessPass: string } {
  // Try to get from secret values first (for deployed functions)
  const secretAccessId = ecareAccessId.value();
  const secretAccessPass = ecareAccessPass.value();

  // Use secrets if available, otherwise fallback to process.env for local development
  const accessId = (secretAccessId || process.env.ECARE_ACCESS_ID || "").trim();
  const accessPass = (secretAccessPass || process.env.ECARE_ACCESS_PASS || "").trim();

  if (!accessId || !accessPass) {
    throw new functions.https.HttpsError(
      "internal",
      "ECARE API credentials not configured. Please set ECARE_ACCESS_ID and ECARE_ACCESS_PASS environment variables or Firebase secrets."
    );
  }

  return { accessId, accessPass };
}

/**
 * Build ECARE API URL with query parameters
 */
function buildEcareUrl(params: Record<string, string>): string {
  const { accessId, accessPass } = getEcareCredentials();
  const url = new URL(ECARE_CONFIG.BASE_URL);
  url.searchParams.set("access_id", accessId);
  url.searchParams.set("access_pass", accessPass);

  for (const [key, value] of Object.entries(params)) {
    url.searchParams.set(key, value);
  }

  return url.toString();
}

/**
 * Call ECARE API with timeout
 */
async function callEcareApi<T>(params: Record<string, string>): Promise<T> {
  const url = buildEcareUrl(params);

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), ECARE_CONFIG.HTTP_TIMEOUT);

  try {
    const response = await fetch(url, { signal: controller.signal });

    if (!response.ok) {
      throw new Error(`ECARE API HTTP error: ${response.status}`);
    }

    const data = await response.json();
    return data as T;
  } finally {
    clearTimeout(timeout);
  }
}

/**
 * Generate unique refid for ECARE
 */
function generateRefId(): string {
  const timestamp = Date.now();
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  let random = "";
  for (let i = 0; i < 6; i++) {
    random += chars[Math.floor(Math.random() * chars.length)];
  }
  return `SHR_${timestamp}_${random}`;
}

// ============================================
// CORE: INITIATE RECHARGE
// ============================================

/**
 * Initiate a mobile recharge or drive offer purchase
 * - Validates user, wallet, and input
 * - Debits wallet atomically
 * - Calls ECARE API
 * - Polls for status
 * - Credits cashback on success
 * - Refunds on failure
 */
export const initiateRecharge = functions.https.onCall(
  { 
    region: REGION,
    secrets: [ecareAccessId, ecareAccessPass],
  },
  async (
    request: functions.https.CallableRequest<InitiateRechargeRequest>
  ): Promise<ApiResponse<{ refid: string; status: string; cashback?: number }>> => {
    try {
      const uid = validateAuthenticated(request.auth);
      const { phone, operator, numberType, amount, type, offerDetails } = request.data;

    // --- 1. INPUT VALIDATION ---
    if (!phone || !operator || !numberType || !amount || !type) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required fields: phone, operator, numberType, amount, type"
      );
    }

    if (!isValidPhoneNumber(phone)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Invalid phone number. Must be 11 digits starting with 01."
      );
    }

    if (!OPERATOR_MAP[operator]) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        `Invalid operator code: ${operator}`
      );
    }

    if (!NUMBER_TYPE_MAP[numberType]) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        `Invalid number type: ${numberType}`
      );
    }

    if (type !== RECHARGE_TYPES.RECHARGE && type !== RECHARGE_TYPES.DRIVE_OFFER) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Type must be 'recharge' or 'drive_offer'"
      );
    }

    // Amount validation
    if (type === RECHARGE_TYPES.RECHARGE) {
      if (amount < ECARE_CONFIG.RECHARGE_MIN_AMOUNT || amount > ECARE_CONFIG.RECHARGE_MAX_AMOUNT) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          `Recharge amount must be between ৳${ECARE_CONFIG.RECHARGE_MIN_AMOUNT} and ৳${ECARE_CONFIG.RECHARGE_MAX_AMOUNT}`
        );
      }
      if (amount % 10 !== 0) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Recharge amount must be a round figure (ending in 0)"
        );
      }
    } else {
      if (amount <= 0) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Amount must be positive"
        );
      }
      if (!offerDetails) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "offerDetails is required for drive offer purchase"
        );
      }
    }

    // --- 2. USER & WALLET CHECKS ---
    const user = await getUserByUid(uid);
    if (!user) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }

    if (user.wallet?.locked) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Your wallet is locked. Contact support."
      );
    }

    const currentBalance = Number(user.wallet?.balanceBDT ?? 0);
    if (Number.isNaN(currentBalance)) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Wallet balance is invalid. Contact support."
      );
    }

    if (currentBalance < amount) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Insufficient wallet balance"
      );
    }

    // --- 3. DAILY LIMIT CHECK ---
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayTimestamp = admin.firestore.Timestamp.fromDate(today);

    let dailyCount = 0;
    try {
      const dailyCountQuery = await db
        .collection(COLLECTIONS.MOBILE_RECHARGE)
        .where("uid", "==", uid)
        .where("type", "==", type)
        .where("createdAt", ">=", todayTimestamp)
        .count()
        .get();

      dailyCount = dailyCountQuery.data().count;
    } catch (error: any) {
      if (error?.code === 9 || error?.message?.includes("index")) {
        console.warn(
          "Daily limit check skipped due to missing index:",
          error?.message || error
        );
        dailyCount = 0;
      } else {
        throw error;
      }
    }
    const maxDaily = type === RECHARGE_TYPES.RECHARGE
      ? ECARE_CONFIG.MAX_DAILY_RECHARGES
      : ECARE_CONFIG.MAX_DAILY_OFFERS;

    if (dailyCount >= maxDaily) {
      throw new functions.https.HttpsError(
        "resource-exhausted",
        `Daily limit reached (${maxDaily} ${type === "recharge" ? "recharges" : "offer purchases"} per day)`
      );
    }

    // --- 4. GENERATE REFID & COMPUTE CASHBACK ---
    const refid = generateRefId();
    const operatorInfo = OPERATOR_MAP[operator];
    const cashbackAmount = type === RECHARGE_TYPES.RECHARGE
      ? Math.round(amount * ECARE_CONFIG.CASHBACK_PERCENT) / 100
      : (offerDetails?.commissionAmount ?? 0);
    const cashbackSource = type === RECHARGE_TYPES.RECHARGE
      ? TRANSACTION_SOURCES.RECHARGE_CASHBACK
      : TRANSACTION_SOURCES.DRIVE_OFFER_CASHBACK;

    // --- 5. ATOMIC WALLET DEBIT + RECORD CREATION ---
    const userRef = db.collection(COLLECTIONS.USERS).doc(uid);
    const rechargeRef = db.collection(COLLECTIONS.MOBILE_RECHARGE).doc(refid);
    const walletTxRef = db.collection(COLLECTIONS.WALLET_TRANSACTIONS).doc();
    const walletTxId = generateTransactionId("WTX");

    let balanceBefore = 0;
    let balanceAfterDebit = 0;

    await db.runTransaction(async (tx) => {
      const freshUser = await tx.get(userRef);
      if (!freshUser.exists) {
        throw new functions.https.HttpsError("not-found", "User not found");
      }

      const userData = freshUser.data() as UserDocument;
      const walletBalance = Number(userData.wallet?.balanceBDT ?? NaN);
      if (Number.isNaN(walletBalance)) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Wallet balance is invalid. Contact support."
        );
      }
      balanceBefore = walletBalance;

      if (balanceBefore < amount) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Insufficient wallet balance"
        );
      }

      balanceAfterDebit = balanceBefore - amount;

      // Debit wallet
      tx.update(userRef, {
        "wallet.balanceBDT": balanceAfterDebit,
        "meta.updatedAt": serverTimestamp(),
      });

      // Wallet transaction record
      tx.set(walletTxRef, {
        id: walletTxId,
        uid,
        type: TRANSACTION_TYPES.DEBIT,
        source: TRANSACTION_SOURCES.RECHARGE_DEBIT,
        amount,
        balanceBefore,
        balanceAfter: balanceAfterDebit,
        description: type === RECHARGE_TYPES.RECHARGE
          ? `Mobile recharge ৳${amount} to ${phone}`
          : `Drive offer ৳${amount} to ${phone}`,
        reference: refid,
        createdAt: serverTimestamp(),
      });

      // Recharge document
      const rechargeDoc: Omit<MobileRechargeDocument, "createdAt" | "updatedAt"> & {
        createdAt: FirebaseFirestore.FieldValue;
        updatedAt: FirebaseFirestore.FieldValue;
      } = {
        refid,
        uid,
        type,
        phone,
        operator,
        operatorName: operatorInfo.name,
        numberType,
        numberTypeName: NUMBER_TYPE_MAP[numberType] || "Unknown",
        amount,
        offer: type === RECHARGE_TYPES.DRIVE_OFFER && offerDetails
          ? {
              offerType: offerDetails.offerType,
              offerTypeName: OFFER_TYPE_MAP[offerDetails.offerType] || offerDetails.offerType,
              minutePack: offerDetails.minutePack,
              internetPack: offerDetails.internetPack,
              smsPack: offerDetails.smsPack,
              callratePack: offerDetails.callratePack,
              validity: offerDetails.validity,
              commissionAmount: offerDetails.commissionAmount,
            }
          : null,
        cashback: {
          amount: cashbackAmount,
          percentage: type === RECHARGE_TYPES.RECHARGE ? ECARE_CONFIG.CASHBACK_PERCENT : null,
          source: cashbackSource,
          credited: false,
        },
        ecare: {
          trxId: null,
          rechargeTrxId: null,
          lastMessage: "",
          pollCount: 0,
        },
        wallet: {
          balanceBefore,
          balanceAfterDebit,
          balanceAfterCashback: null,
        },
        status: RECHARGE_STATUS.INITIATED,
        ecareStatus: null,
        error: null,
        walletTransactionId: walletTxId,
        cashbackTransactionId: null,
        auditLogId: null,
        submittedAt: null,
        completedAt: null,
        createdAt: serverTimestamp() as unknown as FirebaseFirestore.FieldValue,
        updatedAt: serverTimestamp() as unknown as FirebaseFirestore.FieldValue,
      };

      tx.set(rechargeRef, rechargeDoc);
    });

    // --- 6. CALL ECARE RECHARGE API ---
    let ecareResponse: EcareRechargeResponse;
    try {
      ecareResponse = await callEcareApi<EcareRechargeResponse>({
        service: ECARE_CONFIG.SERVICES.RECHARGE,
        operator,
        number_type: numberType,
        number: phone,
        amount: String(amount),
        refid,
      });
    } catch (error) {
      // ECARE unreachable → refund
      await handleRechargeFailure(uid, refid, balanceAfterDebit, amount, {
        code: "ECARE_UNREACHABLE",
        message: `ECARE API error: ${(error as Error).message}`,
      }, type);

      return {
        success: false,
        message: "Recharge service is temporarily unavailable. Your wallet has been refunded.",
        data: { refid, status: RECHARGE_STATUS.REFUNDED },
      };
    }

    // --- 7. PROCESS ECARE RESPONSE ---
    if (ecareResponse.STATUS === "OK" && ecareResponse.RECHARGE_STATUS === "RECEIVED") {
      // Update status to submitted
      await rechargeRef.update({
        status: RECHARGE_STATUS.SUBMITTED,
        "ecare.trxId": ecareResponse.TRXID || null,
        "ecare.lastMessage": ecareResponse.MESSAGE || "",
        ecareStatus: "RECEIVED",
        submittedAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      });

      // --- 8. POLL STATUS ---
      const result = await pollRechargeStatus(uid, refid, balanceAfterDebit, amount, cashbackAmount, cashbackSource, type);
      return result;
    } else {
      // ECARE rejected → refund
      const errorCode = ecareResponse.RECHARGE_STATUS || "UNKNOWN";
      const errorMsg = ecareResponse.MESSAGE || "Recharge request rejected";

      await handleRechargeFailure(uid, refid, balanceAfterDebit, amount, {
        code: errorCode,
        message: errorMsg,
      }, type);

      // Check for LOWBALANCE to alert admin
      if (errorCode === "LOWBALANCE") {
        await createAuditLog({
          actorUid: "system",
          actorRole: "system",
          action: "ecare.low_balance",
          metadata: { refid, message: errorMsg },
        });
      }

      return {
        success: false,
        message: "Recharge failed. Your wallet has been refunded.",
        data: { refid, status: RECHARGE_STATUS.REFUNDED },
        error: { code: errorCode, details: errorMsg },
      };
    }
    } catch (error) {
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      console.error("initiateRecharge error:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Recharge failed. Please try again."
      );
    }
  }
);

// ============================================
// STATUS POLLING
// ============================================

async function pollRechargeStatus(
  uid: string,
  refid: string,
  balanceAfterDebit: number,
  amount: number,
  cashbackAmount: number,
  cashbackSource: string,
  type: string
): Promise<ApiResponse<{ refid: string; status: string; cashback?: number }>> {
  const rechargeRef = db.collection(COLLECTIONS.MOBILE_RECHARGE).doc(refid);

  for (let poll = 0; poll < ECARE_CONFIG.MAX_POLLS; poll++) {
    await sleep(ECARE_CONFIG.POLL_DELAYS[poll] || 60000);

    let statusResponse: EcareStatusResponse;
    try {
      statusResponse = await callEcareApi<EcareStatusResponse>({
        service: ECARE_CONFIG.SERVICES.STATUS,
        refid,
      });
    } catch {
      // Continue polling on network error
      continue;
    }

    await rechargeRef.update({
      "ecare.pollCount": admin.firestore.FieldValue.increment(1),
      "ecare.lastMessage": statusResponse.MESSAGE || "",
      ecareStatus: statusResponse.RECHARGE_STATUS || null,
      updatedAt: serverTimestamp(),
    });

    if (statusResponse.RECHARGE_STATUS === "SUCCESS") {
      // --- SUCCESS: Credit cashback ---
      const cashbackTxId = await creditCashback(
        uid, refid, balanceAfterDebit, cashbackAmount, cashbackSource, type
      );

      await rechargeRef.update({
        status: RECHARGE_STATUS.SUCCESS,
        "ecare.rechargeTrxId": statusResponse.RECHARGE_TRXID || null,
        "cashback.credited": true,
        cashbackTransactionId: cashbackTxId,
        completedAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      });

      // Audit log
      await createAuditLog({
        actorUid: uid,
        actorRole: "user",
        action: type === RECHARGE_TYPES.RECHARGE
          ? AUDIT_ACTIONS.RECHARGE_SUCCESS
          : AUDIT_ACTIONS.DRIVE_OFFER_SUCCESS,
        targetUid: uid,
        targetCollection: COLLECTIONS.MOBILE_RECHARGE,
        targetDocId: refid,
        metadata: { amount, cashback: cashbackAmount },
      });

      return {
        success: true,
        message: type === RECHARGE_TYPES.RECHARGE
          ? `Recharge of ৳${amount} successful! Cashback ৳${cashbackAmount} credited.`
          : `Offer pack activated! Cashback ৳${cashbackAmount} credited.`,
        data: { refid, status: RECHARGE_STATUS.SUCCESS, cashback: cashbackAmount },
      };
    }

    if (statusResponse.RECHARGE_STATUS === "FAILED") {
      // --- FAILED: Refund ---
      await handleRechargeFailure(uid, refid, balanceAfterDebit, amount, {
        code: "ECARE_FAILED",
        message: statusResponse.MESSAGE || "Recharge failed at operator level",
      }, type);

      return {
        success: false,
        message: "Recharge failed. Your wallet has been refunded.",
        data: { refid, status: RECHARGE_STATUS.REFUNDED },
      };
    }

    // PENDING / PROCESSING → update status and continue polling
    if (statusResponse.RECHARGE_STATUS === "PENDING" || statusResponse.RECHARGE_STATUS === "PROCESSING") {
      await rechargeRef.update({
        status: RECHARGE_STATUS.PROCESSING,
        updatedAt: serverTimestamp(),
      });
    }
  }

  // --- MAX POLLS EXCEEDED → pending_verification ---
  await rechargeRef.update({
    status: RECHARGE_STATUS.PENDING_VERIFICATION,
    updatedAt: serverTimestamp(),
  });

  await createAuditLog({
    actorUid: "system",
    actorRole: "system",
    action: type === RECHARGE_TYPES.RECHARGE
      ? AUDIT_ACTIONS.RECHARGE_FAILED
      : AUDIT_ACTIONS.DRIVE_OFFER_FAILED,
    targetUid: uid,
    targetCollection: COLLECTIONS.MOBILE_RECHARGE,
    targetDocId: refid,
    metadata: { reason: "Max polls exceeded", amount },
  });

  return {
    success: false,
    message: "Recharge is being processed. We will update you shortly.",
    data: { refid, status: RECHARGE_STATUS.PENDING_VERIFICATION },
  };
}

// ============================================
// CASHBACK & REFUND HELPERS
// ============================================

async function creditCashback(
  uid: string,
  refid: string,
  balanceAfterDebit: number,
  cashbackAmount: number,
  cashbackSource: string,
  type: string
): Promise<string> {
  const userRef = db.collection(COLLECTIONS.USERS).doc(uid);
  const cashbackTxRef = db.collection(COLLECTIONS.WALLET_TRANSACTIONS).doc();
  const cashbackTxId = generateTransactionId("WTX");

  await db.runTransaction(async (tx) => {
    const freshUser = await tx.get(userRef);
    if (!freshUser.exists) return;

    const userData = freshUser.data() as UserDocument;
    const currentBalance = userData.wallet.balanceBDT;
    const newBalance = currentBalance + cashbackAmount;

    tx.update(userRef, {
      "wallet.balanceBDT": newBalance,
      "meta.updatedAt": serverTimestamp(),
    });

    tx.set(cashbackTxRef, {
      id: cashbackTxId,
      uid,
      type: TRANSACTION_TYPES.CREDIT,
      source: cashbackSource,
      amount: cashbackAmount,
      balanceBefore: currentBalance,
      balanceAfter: newBalance,
      description: type === RECHARGE_TYPES.RECHARGE
        ? `Cashback ${ECARE_CONFIG.CASHBACK_PERCENT}% on recharge ৳${refid.split("_")[1]}`
        : `Drive offer cashback for ${refid}`,
      reference: refid,
      createdAt: serverTimestamp(),
    });
  });

  // Update recharge doc wallet snapshot
  const rechargeRef = db.collection(COLLECTIONS.MOBILE_RECHARGE).doc(refid);
  await rechargeRef.update({
    "wallet.balanceAfterCashback": admin.firestore.FieldValue.increment(0), // Will be set after tx
  });

  return cashbackTxId;
}

async function handleRechargeFailure(
  uid: string,
  refid: string,
  balanceAfterDebit: number,
  amount: number,
  error: { code: string; message: string },
  type: string
): Promise<void> {
  const userRef = db.collection(COLLECTIONS.USERS).doc(uid);
  const rechargeRef = db.collection(COLLECTIONS.MOBILE_RECHARGE).doc(refid);
  const refundTxRef = db.collection(COLLECTIONS.WALLET_TRANSACTIONS).doc();
  const refundTxId = generateTransactionId("WTX");

  await db.runTransaction(async (tx) => {
    const freshUser = await tx.get(userRef);
    if (!freshUser.exists) return;

    const userData = freshUser.data() as UserDocument;
    const currentBalance = userData.wallet.balanceBDT;
    const refundedBalance = currentBalance + amount;

    // Refund wallet
    tx.update(userRef, {
      "wallet.balanceBDT": refundedBalance,
      "meta.updatedAt": serverTimestamp(),
    });

    // Refund transaction record
    tx.set(refundTxRef, {
      id: refundTxId,
      uid,
      type: TRANSACTION_TYPES.CREDIT,
      source: TRANSACTION_SOURCES.RECHARGE_REFUND,
      amount,
      balanceBefore: currentBalance,
      balanceAfter: refundedBalance,
      description: `Refund for failed ${type === RECHARGE_TYPES.RECHARGE ? "recharge" : "drive offer"}: ${refid}`,
      reference: refid,
      createdAt: serverTimestamp(),
    });

    // Update recharge document
    tx.update(rechargeRef, {
      status: RECHARGE_STATUS.REFUNDED,
      error,
      completedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
  });

  // Audit log
  await createAuditLog({
    actorUid: "system",
    actorRole: "system",
    action: type === RECHARGE_TYPES.RECHARGE
      ? AUDIT_ACTIONS.RECHARGE_REFUND
      : AUDIT_ACTIONS.DRIVE_OFFER_REFUND,
    targetUid: uid,
    targetCollection: COLLECTIONS.MOBILE_RECHARGE,
    targetDocId: refid,
    metadata: { amount, error },
  });
}

// ============================================
// DRIVE OFFERS
// ============================================

/**
 * Get cached drive offer list with optional filters
 */
export const getDriveOffers = functions.https.onCall(
  { 
    region: REGION,
    secrets: [ecareAccessId, ecareAccessPass],
  },
  async (
    request: functions.https.CallableRequest<GetDriveOffersRequest>
  ): Promise<ApiResponse<{ offers: DriveOfferItem[]; totalOffers: number }>> => {
    validateAuthenticated(request.auth);
    const { operator, offerType, minAmount, maxAmount } = request.data || {};

    // Get or refresh cache
    let offers = await getCachedOffers();

    // Apply filters
    if (operator) {
      offers = offers.filter((o) => o.operator === operator);
    }
    if (offerType) {
      offers = offers.filter((o) => o.offerType === offerType);
    }
    if (minAmount !== undefined) {
      offers = offers.filter((o) => o.amount >= minAmount);
    }
    if (maxAmount !== undefined) {
      offers = offers.filter((o) => o.amount <= maxAmount);
    }

    // Sort by amount ascending
    offers.sort((a, b) => a.amount - b.amount);

    return {
      success: true,
      message: `Found ${offers.length} offers`,
      data: { offers, totalOffers: offers.length },
    };
  }
);

/**
 * Search drive offers by exact amount (for smart detection)
 */
export const searchDriveOffers = functions.https.onCall(
  { region: REGION },
  async (
    request: functions.https.CallableRequest<{
      amount: number;
      operator: string;
      offerType?: string;
    }>
  ): Promise<ApiResponse<{ offers: DriveOfferItem[] }>> => {
    validateAuthenticated(request.auth);
    const { amount, operator, offerType } = request.data;

    if (!amount || !operator) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "amount and operator are required"
      );
    }

    let offers = await getCachedOffers();

    // Exact amount + operator match
    offers = offers.filter(
      (o) => o.amount === amount && o.operator === operator
    );

    if (offerType) {
      offers = offers.filter((o) => o.offerType === offerType);
    }

    return {
      success: true,
      message: `Found ${offers.length} matching offers`,
      data: { offers },
    };
  }
);

// ============================================
// OFFER CACHE MANAGEMENT
// ============================================

async function getCachedOffers(): Promise<DriveOfferItem[]> {
  const cacheRef = db
    .collection(COLLECTIONS.DRIVE_OFFER_CACHE)
    .doc("latest");
  const cacheDoc = await cacheRef.get();

  if (cacheDoc.exists) {
    const cacheData = cacheDoc.data() as DriveOfferCacheDocument;
    const now = admin.firestore.Timestamp.now();

    if (cacheData.expiresAt && cacheData.expiresAt.toMillis() > now.toMillis()) {
      return cacheData.offers || [];
    }
  }

  // Cache expired or not found → refresh
  return await refreshOfferCache();
}

async function refreshOfferCache(): Promise<DriveOfferItem[]> {
  let ecareResponse: EcareOfferPackResponse;
  try {
    ecareResponse = await callEcareApi<EcareOfferPackResponse>({
      service: ECARE_CONFIG.SERVICES.OFFER_PACK,
    });
  } catch {
    // Return empty if ECARE is unreachable
    return [];
  }

  if (ecareResponse.STATUS !== "OK") {
    return [];
  }

  // Flatten and transform offers
  const operators = ["GP", "BL", "RB", "AR", "TL"];
  const allOffers: DriveOfferItem[] = [];
  const operatorCounts: Record<string, number> = {};

  for (const op of operators) {
    const rawOffers = (ecareResponse as unknown as Record<string, unknown>)[op] as RawEcareOffer[] | undefined;
    if (!rawOffers || !Array.isArray(rawOffers)) {
      operatorCounts[op] = 0;
      continue;
    }

    const transformed = rawOffers
      .filter((o) => o._status === "A")
      .map((o) => ({
        // Use the operator group key for consistent filtering
        operator: op,
        operatorName: OPERATOR_MAP[OFFER_TO_RECHARGE_MAP[op]]?.name || op,
        numberType: o._number_type || "1",
        offerType: o._offer_type || "",
        offerTypeName: OFFER_TYPE_MAP[o._offer_type] || o._offer_type,
        minutePack: o._minute_pack || "-",
        internetPack: o._internet_pack || "-",
        smsPack: o._sms_pack || "-",
        callratePack: o._callrate_pack || "-",
        validity: o._validity || "",
        amount: parseInt(o._amount, 10) || 0,
        commissionAmount: parseFloat(o._commission_amount) || 0,
        status: o._status || "A",
        rawOperator: o._operator || op,
      }));

    allOffers.push(...transformed);
    operatorCounts[op] = transformed.length;
  }

  // Save to cache
  const now = admin.firestore.Timestamp.now();
  const expiresAt = admin.firestore.Timestamp.fromMillis(
    now.toMillis() + ECARE_CONFIG.OFFER_CACHE_TTL_MS
  );

  const cacheRef = db
    .collection(COLLECTIONS.DRIVE_OFFER_CACHE)
    .doc("latest");

  await cacheRef.set({
    offers: allOffers,
    operatorCounts,
    totalOffers: allOffers.length,
    fetchedAt: now,
    expiresAt,
  });

  return allOffers;
}

/**
 * Force-refresh drive offer cache (Admin only)
 */
export const refreshDriveOfferCache = functions.https.onCall(
  { 
    region: REGION,
    secrets: [ecareAccessId, ecareAccessPass],
  },
  async (
    request: functions.https.CallableRequest<void>
  ): Promise<ApiResponse<{ totalOffers: number }>> => {
    const uid = validateAuthenticated(request.auth);
    const user = await getUserByUid(uid);
    if (!user) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }
    if (user.role !== USER_ROLES.SUPER_ADMIN) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Super admin access required"
      );
    }

    const offers = await refreshOfferCache();

    return {
      success: true,
      message: `Refreshed cache with ${offers.length} offers`,
      data: { totalOffers: offers.length },
    };
  }
);

// ============================================
// RECHARGE HISTORY
// ============================================

/**
 * Get user's recharge history (paginated)
 */
export const getRechargeHistory = functions.https.onCall(
  { region: REGION },
  async (
    request: functions.https.CallableRequest<GetRechargeHistoryRequest>
  ): Promise<ApiResponse<{ transactions: MobileRechargeDocument[] }>> => {
    try {
      const uid = validateAuthenticated(request.auth);
      const { limit = 20, startAfter } = request.data || {};

      let query = db
        .collection(COLLECTIONS.MOBILE_RECHARGE)
        .where("uid", "==", uid)
        .orderBy("createdAt", "desc")
        .limit(Math.min(limit, 50));

      if (startAfter) {
        const lastDoc = await db
          .collection(COLLECTIONS.MOBILE_RECHARGE)
          .doc(startAfter)
          .get();
        if (lastDoc.exists) {
          query = query.startAfter(lastDoc);
        }
      }

      const snapshot = await query.get();
      const transactions = snapshot.docs.map(
        (doc) => doc.data() as MobileRechargeDocument
      );

      return {
        success: true,
        message: `Found ${transactions.length} transactions`,
        data: { transactions },
      };
    } catch (error: any) {
      // Better error handling for Firestore index issues
      if (error.code === 9 || error.message?.includes("index")) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Database index required. Please create a composite index on 'mobile_recharge' collection for fields: uid (Ascending) + createdAt (Descending). Check Firebase Console for index creation link."
        );
      }
      throw error;
    }
  }
);

// ============================================
// ADMIN FUNCTIONS
// ============================================

/**
 * Check ECARE merchant balance (Admin only)
 */
export const getEcareBalance = functions.https.onCall(
  { 
    region: REGION,
    secrets: [ecareAccessId, ecareAccessPass],
  },
  async (
    request: functions.https.CallableRequest<void>
  ): Promise<
    ApiResponse<{
      balance: string;
      MAIN_BALANCE: string;
      STOCK_BALANCE: string;
      COMMISSION_TYPE: string;
      COMMISSION_RATE: string;
      MESSAGE: string;
      fullResponse: EcareBalanceResponse;
    }>
  > => {
    const uid = validateAuthenticated(request.auth);
    const user = await getUserByUid(uid);
    if (!user) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }
    validateMinimumRole(user.role, "admin");

    console.log("Calling ECARE Balance API with service:", ECARE_CONFIG.SERVICES.BALANCE);
    
    const response = await callEcareApi<EcareBalanceResponse>({
      service: ECARE_CONFIG.SERVICES.BALANCE,
    });

    console.log("ECARE Balance API response:", JSON.stringify(response));

    // Check if API call was successful
    if (response.STATUS !== "OK") {
      console.error("ECARE Balance API returned non-OK status:", response.STATUS, response.MESSAGE);
      throw new functions.https.HttpsError(
        "internal",
        `ECARE API Error: ${response.MESSAGE || "Unknown error"}`
      );
    }

    // Extract main balance from ECARE response
    const balance = response.MAIN_BALANCE || "0";
    console.log("Extracted balance:", balance);

    return {
      success: true,
      message: "Balance retrieved",
      data: {
        balance,
        MAIN_BALANCE: response.MAIN_BALANCE || "0",
        STOCK_BALANCE: response.STOCK_BALANCE || "0",
        COMMISSION_TYPE: response.COMMISSION_TYPE || "-",
        COMMISSION_RATE: response.COMMISSION_RATE || "-",
        MESSAGE: response.MESSAGE,
        fullResponse: response,
      },
    };
  }
);

/**
 * Admin: Manually check ECARE status for a pending transaction
 */
export const adminRechargeStatus = functions.https.onCall(
  { 
    region: REGION,
    secrets: [ecareAccessId, ecareAccessPass],
  },
  async (
    request: functions.https.CallableRequest<{ refid: string }>
  ): Promise<ApiResponse<EcareStatusResponse>> => {
    const uid = validateAuthenticated(request.auth);
    const user = await getUserByUid(uid);
    if (!user) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }
    validateMinimumRole(user.role, "admin");

    const { refid, refId } = (request.data || {}) as { refid?: string; refId?: string };
    const resolvedRefId = refid || refId;
    if (!resolvedRefId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "refid is required"
      );
    }

    const response = await callEcareApi<EcareStatusResponse>({
      service: ECARE_CONFIG.SERVICES.STATUS,
      refid: resolvedRefId,
    });

    return {
      success: true,
      message: "Status retrieved",
      data: response,
    };
  }
);

/**
 * Admin: Get all recharge history with filters (Admin only)
 */
export const getAdminRechargeHistory = functions.https.onCall(
  { region: REGION },
  async (
    request: functions.https.CallableRequest<{
      limit?: number;
      startAfter?: string;
      startAfterTimestamp?: number | string;
      status?: string;
      type?: string;
      uid?: string;
      userId?: string;
    }>
  ): Promise<ApiResponse<{ transactions: MobileRechargeDocument[]; hasMore: boolean }>> => {
    const uid = validateAuthenticated(request.auth);
    const user = await getUserByUid(uid);
    if (!user) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }
    validateMinimumRole(user.role, "admin");

    const {
      limit = 50,
      startAfter,
      startAfterTimestamp,
      status,
      type,
      uid: targetUid,
      userId,
    } = request.data || {};
    const resolvedUid = targetUid || userId;

    let query: FirebaseFirestore.Query = db.collection(COLLECTIONS.MOBILE_RECHARGE);

    // Apply filters
    if (resolvedUid) {
      query = query.where("uid", "==", resolvedUid);
    }
    if (status) {
      if (status === "pending") {
        query = query.where("status", "in", [
          RECHARGE_STATUS.INITIATED,
          RECHARGE_STATUS.SUBMITTED,
          RECHARGE_STATUS.PROCESSING,
          RECHARGE_STATUS.PENDING_VERIFICATION,
        ]);
      } else {
        query = query.where("status", "==", status);
      }
    }
    if (type) {
      query = query.where("type", "==", type);
    }

    const safeLimit = Math.min(typeof limit === "number" ? limit : Number(limit) || 50, 100);
    query = query.orderBy("createdAt", "desc").limit(safeLimit);

    if (startAfter) {
      const lastDoc = await db
        .collection(COLLECTIONS.MOBILE_RECHARGE)
        .doc(startAfter)
        .get();
      if (lastDoc.exists) {
        query = query.startAfter(lastDoc);
      }
    } else if (startAfterTimestamp) {
      const tsNumber =
        typeof startAfterTimestamp === "number"
          ? startAfterTimestamp
          : Number(startAfterTimestamp);
      if (!Number.isNaN(tsNumber)) {
        query = query.startAfter(admin.firestore.Timestamp.fromMillis(tsNumber));
      }
    }

    let snapshot: FirebaseFirestore.QuerySnapshot;
    try {
      snapshot = await query.get();
    } catch (error: any) {
      if (error?.code === 9 || error?.message?.includes("index")) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Database index required. Please create a composite index on 'mobile_recharge' for the selected filters. Check Firebase Console for the index creation link."
        );
      }
      throw error;
    }

    const transactions = snapshot.docs.map((doc) => doc.data() as MobileRechargeDocument);
    const hasMore = snapshot.docs.length === safeLimit;

    return {
      success: true,
      message: `Found ${transactions.length} transactions`,
      data: { transactions, hasMore },
    };
  }
);

/**
 * Admin: Get recharge statistics (Admin only)
 */
export const getRechargeStats = functions.https.onCall(
  { region: REGION },
  async (
    request: functions.https.CallableRequest<{ period?: string }>
  ): Promise<ApiResponse<{
    totalRecharges: number;
    totalDriveOffers: number;
    totalAmount: number;
    totalCashback: number;
    totalCount: number;
    successCount: number;
    successRate: number;
    avgAmount: number;
    pendingCount: number;
    failedCount: number;
  }>> => {
    const uid = validateAuthenticated(request.auth);
    const user = await getUserByUid(uid);
    if (!user) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }
    validateMinimumRole(user.role, "admin");

    const { period = "all" } = request.data || {};

    let query: FirebaseFirestore.Query = db.collection(COLLECTIONS.MOBILE_RECHARGE);

    // Apply time filter
    if (period === "today") {
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      query = query.where("createdAt", ">=", admin.firestore.Timestamp.fromDate(today));
    } else if (period === "week") {
      const weekAgo = new Date();
      weekAgo.setDate(weekAgo.getDate() - 7);
      query = query.where("createdAt", ">=", admin.firestore.Timestamp.fromDate(weekAgo));
    } else if (period === "month") {
      const monthAgo = new Date();
      monthAgo.setMonth(monthAgo.getMonth() - 1);
      query = query.where("createdAt", ">=", admin.firestore.Timestamp.fromDate(monthAgo));
    } else if (period === "year") {
      const yearAgo = new Date();
      yearAgo.setFullYear(yearAgo.getFullYear() - 1);
      query = query.where("createdAt", ">=", admin.firestore.Timestamp.fromDate(yearAgo));
    }

    const snapshot = await query.get();
    const transactions = snapshot.docs.map((doc) => doc.data() as MobileRechargeDocument);

    let totalRecharges = 0;
    let totalDriveOffers = 0;
    let totalAmount = 0;
    let totalCashback = 0;
    let successCount = 0;
    let pendingCount = 0;
    let failedCount = 0;

    transactions.forEach((tx) => {
      if (tx.type === RECHARGE_TYPES.RECHARGE) {
        totalRecharges++;
      } else {
        totalDriveOffers++;
      }

      totalAmount += tx.amount;

      if (tx.status === RECHARGE_STATUS.SUCCESS) {
        successCount++;
        totalCashback += tx.cashback.amount;
      } else if (
        tx.status === RECHARGE_STATUS.INITIATED ||
        tx.status === RECHARGE_STATUS.SUBMITTED ||
        tx.status === RECHARGE_STATUS.PROCESSING ||
        tx.status === RECHARGE_STATUS.PENDING_VERIFICATION
      ) {
        pendingCount++;
      } else if (
        tx.status === RECHARGE_STATUS.FAILED ||
        tx.status === RECHARGE_STATUS.REFUNDED
      ) {
        failedCount++;
      }
    });

    const totalCount = transactions.length;
    const successRate =
      transactions.length > 0 ? Math.round((successCount / transactions.length) * 100) : 0;
    const avgAmount = transactions.length > 0 ? totalAmount / transactions.length : 0;

    return {
      success: true,
      message: "Statistics retrieved",
      data: {
        totalRecharges,
        totalDriveOffers,
        totalAmount,
        totalCashback,
        successRate,
        pendingCount,
        failedCount,
        totalCount,
        successCount,
        avgAmount,
      },
    };
  }
);

/**
 * Admin: Retry a failed/pending recharge (Admin only)
 */
export const adminRetryRecharge = functions.https.onCall(
  { 
    region: REGION,
    secrets: [ecareAccessId, ecareAccessPass],
  },
  async (
    request: functions.https.CallableRequest<{ refid: string }>
  ): Promise<ApiResponse<{ status: string; message: string }>> => {
    const uid = validateAuthenticated(request.auth);
    const user = await getUserByUid(uid);
    if (!user) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }
    validateMinimumRole(user.role, "admin");

    const { refid, refId } = (request.data || {}) as { refid?: string; refId?: string };
    const resolvedRefId = refid || refId;
    if (!resolvedRefId) {
      throw new functions.https.HttpsError("invalid-argument", "refid is required");
    }

    const rechargeRef = db.collection(COLLECTIONS.MOBILE_RECHARGE).doc(resolvedRefId);
    const rechargeDoc = await rechargeRef.get();

    if (!rechargeDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Recharge transaction not found");
    }

    const recharge = rechargeDoc.data() as MobileRechargeDocument;

    if (
      recharge.status !== RECHARGE_STATUS.PENDING_VERIFICATION &&
      recharge.status !== RECHARGE_STATUS.SUBMITTED &&
      recharge.status !== RECHARGE_STATUS.PROCESSING
    ) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Only pending/processing transactions can be retried"
      );
    }

    // Check ECARE status
    const statusResponse = await callEcareApi<EcareStatusResponse>({
      service: ECARE_CONFIG.SERVICES.STATUS,
      refid: resolvedRefId,
    });

    await rechargeRef.update({
      "ecare.lastMessage": statusResponse.MESSAGE || "",
      ecareStatus: statusResponse.RECHARGE_STATUS || null,
      updatedAt: serverTimestamp(),
    });

    if (statusResponse.RECHARGE_STATUS === "SUCCESS") {
      // Credit cashback
      const cashbackTxId = await creditCashback(
        recharge.uid,
        resolvedRefId,
        recharge.wallet.balanceAfterDebit,
        recharge.cashback.amount,
        recharge.cashback.source,
        recharge.type
      );

      await rechargeRef.update({
        status: RECHARGE_STATUS.SUCCESS,
        "ecare.rechargeTrxId": statusResponse.RECHARGE_TRXID || null,
        "cashback.credited": true,
        cashbackTransactionId: cashbackTxId,
        completedAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      });

      return {
        success: true,
        message: "Recharge marked as successful and cashback credited",
        data: { status: RECHARGE_STATUS.SUCCESS, message: statusResponse.MESSAGE },
      };
    } else if (statusResponse.RECHARGE_STATUS === "FAILED") {
      // Refund
      await handleRechargeFailure(
        recharge.uid,
        resolvedRefId,
        recharge.wallet.balanceAfterDebit,
        recharge.amount,
        {
          code: "ECARE_FAILED",
          message: statusResponse.MESSAGE || "Recharge failed at operator level",
        },
        recharge.type
      );

      return {
        success: false,
        message: "Recharge failed and refunded",
        data: { status: RECHARGE_STATUS.REFUNDED, message: statusResponse.MESSAGE },
      };
    }

    return {
      success: true,
      message: `Status: ${statusResponse.RECHARGE_STATUS}`,
      data: { status: statusResponse.RECHARGE_STATUS, message: statusResponse.MESSAGE },
    };
  }
);
