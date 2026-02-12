/**
 * SHIRAH Cloud Functions - Rewards Module
 * Handles reward points, streaks, ad views, and conversions
 */

import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import {
  COLLECTIONS,
  TRANSACTION_TYPES,
  TRANSACTION_SOURCES,
  AUDIT_ACTIONS,
  REGION,
} from "../../config/constants";
import { getAppConfig } from "../../config/dynamic-config";
import {
  RewardTransaction,
  StreakData,
  AdViewLog,
  UserDocument,
  ApiResponse,
} from "../../types";
import {
  serverTimestamp,
  generateTransactionId,
  getStreakMultiplier,
  getTodayDateString,
  areConsecutiveDays,
  increment,
  hashSensitiveData,
} from "../../utils/helpers";
import {
  validateAuthenticated,
  validateRewardConversion,
  validateDailyAdLimit,
  validateUserAccountState,
  validateUserVerifiedOrSubscribed,
} from "../../utils/validators";
import { createAuditLog } from "../audit/audit-logging";
import { getUserByUid, resetDailyLimitsIfNeeded } from "../users/user-management";

const db = admin.firestore();

/**
 * Credit reward points to user
 */
export async function creditRewardPoints(
  uid: string,
  points: number,
  source: string,
  description: string,
  reference?: string
): Promise<RewardTransaction> {
  const userRef = db.collection(COLLECTIONS.USERS).doc(uid);
  const transactionRef = db.collection(COLLECTIONS.REWARD_TRANSACTIONS).doc();
  const transactionId = generateTransactionId("RPT");

  let transaction: RewardTransaction | null = null;

  await db.runTransaction(async (tx) => {
    const userDoc = await tx.get(userRef);
    if (!userDoc.exists) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }

    const userData = userDoc.data() as UserDocument;
    const pointsBefore = userData.wallet.rewardPoints;
    const pointsAfter = pointsBefore + points;

    transaction = {
      id: transactionId,
      uid,
      type: TRANSACTION_TYPES.CREDIT,
      source,
      points,
      pointsBefore,
      pointsAfter,
      description,
      reference: reference || null,
      createdAt: admin.firestore.Timestamp.now(),
    };

    tx.update(userRef, {
      "wallet.rewardPoints": pointsAfter,
      "meta.updatedAt": serverTimestamp(),
    });

    tx.set(transactionRef, {
      ...transaction,
      createdAt: serverTimestamp(),
    });
  });

  return transaction!;
}

/**
 * Debit reward points from user
 */
export async function debitRewardPoints(
  uid: string,
  points: number,
  source: string,
  description: string,
  reference?: string
): Promise<RewardTransaction> {
  const userRef = db.collection(COLLECTIONS.USERS).doc(uid);
  const transactionRef = db.collection(COLLECTIONS.REWARD_TRANSACTIONS).doc();
  const transactionId = generateTransactionId("RPT");

  let transaction: RewardTransaction | null = null;

  await db.runTransaction(async (tx) => {
    const userDoc = await tx.get(userRef);
    if (!userDoc.exists) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }

    const userData = userDoc.data() as UserDocument;
    const pointsBefore = userData.wallet.rewardPoints;

    if (pointsBefore < points) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Insufficient reward points"
      );
    }

    const pointsAfter = pointsBefore - points;

    transaction = {
      id: transactionId,
      uid,
      type: TRANSACTION_TYPES.DEBIT,
      source,
      points,
      pointsBefore,
      pointsAfter,
      description,
      reference: reference || null,
      createdAt: admin.firestore.Timestamp.now(),
    };

    tx.update(userRef, {
      "wallet.rewardPoints": pointsAfter,
      "meta.updatedAt": serverTimestamp(),
    });

    tx.set(transactionRef, {
      ...transaction,
      createdAt: serverTimestamp(),
    });
  });

  return transaction!;
}

/**
 * Get or create streak data for user
 */
export async function getOrCreateStreakData(uid: string): Promise<StreakData> {
  const streakRef = db.collection(COLLECTIONS.STREAK_DATA).doc(uid);
  const doc = await streakRef.get();

  if (doc.exists) {
    return doc.data() as StreakData;
  }

  const newStreak: Omit<StreakData, "updatedAt"> & {
    updatedAt: FirebaseFirestore.FieldValue;
  } = {
    uid,
    currentStreak: 0,
    lastActiveDate: "",
    highestStreak: 0,
    updatedAt: serverTimestamp(),
  };

  await streakRef.set(newStreak);

  return {
    ...newStreak,
    updatedAt: admin.firestore.Timestamp.now(),
  } as StreakData;
}

/**
 * Update streak on ad view
 */
export async function updateStreak(uid: string): Promise<StreakData> {
  const streakRef = db.collection(COLLECTIONS.STREAK_DATA).doc(uid);
  const today = getTodayDateString();

  let updatedStreak: StreakData | null = null;

  await db.runTransaction(async (tx) => {
    const doc = await tx.get(streakRef);
    let streakData: StreakData;

    if (!doc.exists) {
      streakData = {
        uid,
        currentStreak: 0,
        lastActiveDate: "",
        highestStreak: 0,
        updatedAt: admin.firestore.Timestamp.now(),
      };
    } else {
      streakData = doc.data() as StreakData;
    }

    // Check if already updated today
    if (streakData.lastActiveDate === today) {
      updatedStreak = streakData;
      return;
    }

    // Calculate new streak
    let newStreak: number;
    if (!streakData.lastActiveDate) {
      // First ever activity
      newStreak = 1;
    } else if (areConsecutiveDays(streakData.lastActiveDate, today)) {
      // Consecutive day, increment streak
      newStreak = streakData.currentStreak + 1;
    } else {
      // Streak broken, reset to 1
      newStreak = 1;
    }

    const highestStreak = Math.max(newStreak, streakData.highestStreak);

    updatedStreak = {
      uid,
      currentStreak: newStreak,
      lastActiveDate: today,
      highestStreak,
      updatedAt: admin.firestore.Timestamp.now(),
    };

    tx.set(streakRef, {
      ...updatedStreak,
      updatedAt: serverTimestamp(),
    });
  });

  return updatedStreak!;
}

/**
 * Cloud Function: Record ad view and earn reward points
 */
export const recordAdView = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<{
    adType: string;
    deviceId: string;
  }>): Promise<ApiResponse<{
    pointsEarned: number;
    multiplier: number;
    currentStreak: number;
    dailyAdsRemaining: number;
  }>> => {
    const uid = validateAuthenticated(request.auth);
    const { adType, deviceId } = request.data;

    if (!adType || !deviceId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "adType and deviceId are required"
      );
    }

    // Reset daily limits if needed
    await resetDailyLimitsIfNeeded(uid);

    const config = await getAppConfig();
    const user = await getUserByUid(uid);
    if (!user) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }

    // Validate user state
    validateUserAccountState(user.status.accountState);
    validateDailyAdLimit(user.limits.dailyAdsViewed, config.ads.maxDailyAds);

    // Update streak
    const streak = await updateStreak(uid);
    const multiplier = getStreakMultiplier(streak.currentStreak, config.streak);
    const basePoints = config.ads.pointsPerAd;
    const pointsEarned = Math.floor(basePoints * multiplier);

    // Credit reward points and log ad view
    await db.runTransaction(async (tx) => {
      const userRef = db.collection(COLLECTIONS.USERS).doc(uid);
      const adLogRef = db.collection(COLLECTIONS.AD_VIEW_LOGS).doc();
      const rewardTxRef = db.collection(COLLECTIONS.REWARD_TRANSACTIONS).doc();

      // Update user
      tx.update(userRef, {
        "wallet.rewardPoints": increment(pointsEarned),
        "limits.dailyAdsViewed": increment(1),
        "meta.updatedAt": serverTimestamp(),
        "meta.lastActiveAt": serverTimestamp(),
      });

      // Log ad view
      const adLog: Omit<AdViewLog, "id" | "createdAt"> & {
        id: string;
        createdAt: FirebaseFirestore.FieldValue;
      } = {
        id: adLogRef.id,
        uid,
        adType,
        pointsEarned,
        multiplier,
        deviceId: hashSensitiveData(deviceId),
        ipHash: "",
        createdAt: serverTimestamp(),
      };
      tx.set(adLogRef, adLog);

      // Log reward transaction
      tx.set(rewardTxRef, {
        id: generateTransactionId("RPT"),
        uid,
        type: TRANSACTION_TYPES.CREDIT,
        source: TRANSACTION_SOURCES.AD_REWARD,
        points: pointsEarned,
        description: `Ad view reward (${multiplier}x multiplier, Day ${streak.currentStreak})`,
        reference: adLogRef.id,
        createdAt: serverTimestamp(),
      });
    });

    return {
      success: true,
      message: "Ad view recorded",
      data: {
        pointsEarned,
        multiplier,
        currentStreak: streak.currentStreak,
        dailyAdsRemaining: config.ads.maxDailyAds - user.limits.dailyAdsViewed - 1,
      },
    };
  }
);

/**
 * Cloud Function: Convert reward points to wallet balance
 */
export const convertRewardPoints = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<{ points: number }>): Promise<ApiResponse<{
    pointsConverted: number;
    amountCredited: number;
    fee: number;
    newRewardBalance: number;
    newWalletBalance: number;
  }>> => {
    const uid = validateAuthenticated(request.auth);
    const { points } = request.data;

    // Reset daily limits if needed
    await resetDailyLimitsIfNeeded(uid);

    const user = await getUserByUid(uid);
    if (!user) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }

    // Validate user state and conversion
    validateUserAccountState(user.status.accountState);
    validateUserVerifiedOrSubscribed(user.status.verified, user.status.subscription);

    const config = await getAppConfig();
    validateRewardConversion(points, user.wallet.rewardPoints, user.limits.dailyRewardConverted, config.rewardPoints);

    // Calculate conversion
    const grossAmount = points / config.rewardPoints.conversionRate;
    const fee = Math.floor(grossAmount * (config.rewardPoints.conversionFeePercent / 100));
    const netAmount = grossAmount - fee;

    // Process conversion
    let newRewardBalance: number = 0;
    let newWalletBalance: number = 0;

    await db.runTransaction(async (tx) => {
      const userRef = db.collection(COLLECTIONS.USERS).doc(uid);
      const userDoc = await tx.get(userRef);
      const userData = userDoc.data() as UserDocument;

      // Double-check points
      if (userData.wallet.rewardPoints < points) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Insufficient reward points"
        );
      }

      newRewardBalance = userData.wallet.rewardPoints - points;
      newWalletBalance = userData.wallet.balanceBDT + netAmount;

      // Update user
      tx.update(userRef, {
        "wallet.rewardPoints": newRewardBalance,
        "wallet.balanceBDT": newWalletBalance,
        "limits.dailyRewardConverted": increment(1),
        "meta.updatedAt": serverTimestamp(),
      });

      // Log reward debit
      const rewardTxRef = db.collection(COLLECTIONS.REWARD_TRANSACTIONS).doc();
      tx.set(rewardTxRef, {
        id: generateTransactionId("RPT"),
        uid,
        type: TRANSACTION_TYPES.DEBIT,
        source: TRANSACTION_SOURCES.REWARD_CONVERSION,
        points,
        pointsBefore: userData.wallet.rewardPoints,
        pointsAfter: newRewardBalance,
        description: `Converted to ৳${netAmount} (fee: ৳${fee})`,
        createdAt: serverTimestamp(),
      });

      // Log wallet credit
      const walletTxRef = db.collection(COLLECTIONS.WALLET_TRANSACTIONS).doc();
      tx.set(walletTxRef, {
        id: generateTransactionId("WTX"),
        uid,
        type: TRANSACTION_TYPES.CREDIT,
        source: TRANSACTION_SOURCES.REWARD_CONVERSION,
        amount: netAmount,
        balanceBefore: userData.wallet.balanceBDT,
        balanceAfter: newWalletBalance,
        description: `Reward points conversion (${points} points)`,
        createdAt: serverTimestamp(),
      });
    });

    await createAuditLog({
      actorUid: uid,
      actorRole: user.role,
      action: AUDIT_ACTIONS.REWARD_CONVERT,
      targetUid: uid,
      metadata: {
        pointsConverted: points,
        grossAmount,
        fee,
        netAmount,
      },
    });

    return {
      success: true,
      message: "Reward points converted successfully",
      data: {
        pointsConverted: points,
        amountCredited: netAmount,
        fee,
        newRewardBalance,
        newWalletBalance,
      },
    };
  }
);

/**
 * Cloud Function: Get streak info
 */
export const getStreakInfo = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest): Promise<ApiResponse<{
    currentStreak: number;
    highestStreak: number;
    lastActiveDate: string;
    currentMultiplier: number;
    nextMultiplier: number;
    dailyAdsViewed: number;
    dailyAdsRemaining: number;
    dailyMaxPoints: number;
  }>> => {
    const uid = validateAuthenticated(request.auth);

    // Reset daily limits if needed
    await resetDailyLimitsIfNeeded(uid);

    const [user, streak] = await Promise.all([
      getUserByUid(uid),
      getOrCreateStreakData(uid),
    ]);

    if (!user) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }

    const config = await getAppConfig();
    const currentMultiplier = getStreakMultiplier(streak.currentStreak, config.streak);
    const nextMultiplier = getStreakMultiplier(streak.currentStreak + 1, config.streak);
    const dailyMaxPoints = Math.floor(config.ads.baseDailyPoints * currentMultiplier);

    return {
      success: true,
      message: "Streak info retrieved",
      data: {
        currentStreak: streak.currentStreak,
        highestStreak: streak.highestStreak,
        lastActiveDate: streak.lastActiveDate,
        currentMultiplier,
        nextMultiplier,
        dailyAdsViewed: user.limits.dailyAdsViewed,
        dailyAdsRemaining: config.ads.maxDailyAds - user.limits.dailyAdsViewed,
        dailyMaxPoints,
      },
    };
  }
);

/**
 * Get reward transactions for user
 */
export async function getRewardTransactions(
  uid: string,
  limit: number = 50
): Promise<RewardTransaction[]> {
  const snapshot = await db
    .collection(COLLECTIONS.REWARD_TRANSACTIONS)
    .where("uid", "==", uid)
    .orderBy("createdAt", "desc")
    .limit(limit)
    .get();

  return snapshot.docs.map((doc) => doc.data() as RewardTransaction);
}

/**
 * Cloud Function: Get reward transactions
 */
export const getMyRewardTransactions = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<{ limit?: number }>): Promise<ApiResponse<RewardTransaction[]>> => {
    const uid = validateAuthenticated(request.auth);
    const limit = request.data?.limit || 50;

    const transactions = await getRewardTransactions(uid, limit);

    return {
      success: true,
      message: "Reward transactions retrieved",
      data: transactions,
    };
  }
);

/**
 * Credit reward points in transaction (for batch operations)
 */
export function creditRewardPointsInTransaction(
  transaction: FirebaseFirestore.Transaction,
  uid: string,
  points: number,
  source: string,
  description: string,
  reference?: string
): void {
  const userRef = db.collection(COLLECTIONS.USERS).doc(uid);
  const transactionRef = db.collection(COLLECTIONS.REWARD_TRANSACTIONS).doc();

  transaction.update(userRef, {
    "wallet.rewardPoints": increment(points),
    "meta.updatedAt": serverTimestamp(),
  });

  transaction.set(transactionRef, {
    id: generateTransactionId("RPT"),
    uid,
    type: TRANSACTION_TYPES.CREDIT,
    source,
    points,
    description,
    reference: reference || null,
    createdAt: serverTimestamp(),
  });
}
