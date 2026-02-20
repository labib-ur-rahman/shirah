/**
 * SHIRAH Cloud Functions - Network Module
 * Handles upline/downline relationships, network stats, and graph operations
 */

import * as admin from "firebase-admin";
import {
  COLLECTIONS,
  UNDISTRIBUTED_REASONS,
} from "../../config/constants";
import { getAppConfig } from "../../config/dynamic-config";
import { UserUplines, UserRelation, UserNetworkStats, LevelStats, DistributionResult, UndistributedEntry, UserDocument } from "../../types";
import {
  serverTimestamp,
  getUplineKey,
  createEmptyLevelStats,
  increment,
} from "../../utils/helpers";

const db = admin.firestore();

/**
 * Build upline chain for a new user
 * Returns the upline document structure (u1...uN)
 */
export async function buildUplineChain(parentUid: string): Promise<UserUplines> {
  const config = await getAppConfig();
  const maxDepth = config.network.maxDepth;
  const parentUplinesRef = db.collection(COLLECTIONS.USER_UPLINES).doc(parentUid);
  const parentUplinesDoc = await parentUplinesRef.get();

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const uplines: Record<string, any> = {
    maxDepth: maxDepth,
  };

  // Set u1 as the direct parent
  uplines.u1 = parentUid;

  if (parentUplinesDoc.exists) {
    const parentUplines = parentUplinesDoc.data() as UserUplines;

    // Shift parent's uplines up by one level
    for (let level = 2; level <= maxDepth; level++) {
      const parentKey = getUplineKey(level - 1, maxDepth);
      const newKey = getUplineKey(level, maxDepth);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      uplines[newKey] = (parentUplines as unknown as Record<string, unknown>)[parentKey] || null;
    }
  } else {
    // Parent has no uplines, fill remaining with null
    for (let level = 2; level <= maxDepth; level++) {
      const key = getUplineKey(level, maxDepth);
      uplines[key] = null;
    }
  }

  return uplines as UserUplines;
}

/**
 * Create upline document for a new user
 */
export async function createUserUplines(
  uid: string,
  parentUid: string | null
): Promise<void> {
  const config = await getAppConfig();
  const maxDepth = config.network.maxDepth;
  const uplinesRef = db.collection(COLLECTIONS.USER_UPLINES).doc(uid);

  if (!parentUid) {
    // Root user (no parent) - all uplines are null
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const emptyUplines: Record<string, any> = {
      maxDepth: maxDepth,
    };
    for (let level = 1; level <= maxDepth; level++) {
      const key = getUplineKey(level, maxDepth);
      emptyUplines[key] = null;
    }
    await uplinesRef.set({
      ...emptyUplines,
      createdAt: serverTimestamp(),
    });
    return;
  }

  const uplineChain = await buildUplineChain(parentUid);
  await uplinesRef.set({
    ...uplineChain,
    createdAt: serverTimestamp(),
  });
}

/**
 * Create upline document in transaction
 */
export function createUserUplinesInTransaction(
  transaction: FirebaseFirestore.Transaction,
  uid: string,
  uplineChain: Partial<UserUplines>,
  maxDepth: number
): void {
  const uplinesRef = db.collection(COLLECTIONS.USER_UPLINES).doc(uid);
  transaction.set(uplinesRef, {
    ...uplineChain,
    maxDepth: maxDepth,
    createdAt: serverTimestamp(),
  });
}

/**
 * Create user relations (graph edges) for audit and analytics
 */
export async function createUserRelations(
  descendantUid: string,
  uplines: UserUplines,
  verified: boolean = false,
  subscribed: boolean = false
): Promise<void> {
  const config = await getAppConfig();
  const maxDepth = config.network.maxDepth;
  const batch = db.batch();

  for (let level = 1; level <= maxDepth; level++) {
    const key = getUplineKey(level) as keyof UserUplines;
    const ancestorUid = uplines[key] as string | null;

    if (!ancestorUid) break;

    const relationRef = db.collection(COLLECTIONS.USER_RELATIONS).doc();
    const relation: Omit<UserRelation, "createdAt"> & {
      createdAt: FirebaseFirestore.FieldValue;
    } = {
      ancestorUid,
      descendantUid,
      level,
      descendantVerified: verified,
      descendantSubscribed: subscribed,
      createdAt: serverTimestamp(),
    };

    batch.set(relationRef, relation);
  }

  await batch.commit();
}

/**
 * Create user relations in transaction
 */
export function createUserRelationsInTransaction(
  transaction: FirebaseFirestore.Transaction,
  descendantUid: string,
  uplines: Partial<UserUplines>,
  verified: boolean = false,
  subscribed: boolean = false,
  maxDepth: number = 15
): void {
  for (let level = 1; level <= maxDepth; level++) {
    const key = getUplineKey(level) as keyof UserUplines;
    const ancestorUid = uplines[key] as string | null;

    if (!ancestorUid) break;

    const relationRef = db.collection(COLLECTIONS.USER_RELATIONS).doc();
    const relation = {
      ancestorUid,
      descendantUid,
      level,
      descendantVerified: verified,
      descendantSubscribed: subscribed,
      createdAt: serverTimestamp(),
    };

    transaction.set(relationRef, relation);
  }
}

/**
 * Initialize network stats for a new user
 */
export async function initializeNetworkStats(uid: string): Promise<void> {
  const config = await getAppConfig();
  const maxDepth = config.network.maxDepth;
  const statsRef = db.collection(COLLECTIONS.USER_NETWORK_STATS).doc(uid);

  const stats: Record<string, LevelStats | FirebaseFirestore.FieldValue> = {};
  for (let level = 1; level <= maxDepth; level++) {
    stats[`level${level}`] = createEmptyLevelStats();
  }
  stats.updatedAt = serverTimestamp();

  await statsRef.set(stats);
}

/**
 * Initialize network stats in transaction
 */
export function initializeNetworkStatsInTransaction(
  transaction: FirebaseFirestore.Transaction,
  uid: string,
  maxDepth: number = 15
): void {
  const statsRef = db.collection(COLLECTIONS.USER_NETWORK_STATS).doc(uid);

  const stats: Record<string, LevelStats | FirebaseFirestore.FieldValue> = {};
  for (let level = 1; level <= maxDepth; level++) {
    stats[`level${level}`] = createEmptyLevelStats();
  }
  stats.updatedAt = serverTimestamp();

  transaction.set(statsRef, stats);
}

/**
 * Increment network stats for uplines when a new user joins
 */
export async function incrementNetworkStatsOnJoin(
  uplines: UserUplines
): Promise<void> {
  const config = await getAppConfig();
  const maxDepth = config.network.maxDepth;
  const batch = db.batch();

  for (let level = 1; level <= maxDepth; level++) {
    const key = getUplineKey(level) as keyof UserUplines;
    const ancestorUid = uplines[key] as string | null;

    if (!ancestorUid) break;

    const statsRef = db.collection(COLLECTIONS.USER_NETWORK_STATS).doc(ancestorUid);
    batch.update(statsRef, {
      [`level${level}.total`]: increment(1),
      updatedAt: serverTimestamp(),
    });
  }

  await batch.commit();
}

/**
 * Increment network stats in transaction
 */
export function incrementNetworkStatsInTransaction(
  transaction: FirebaseFirestore.Transaction,
  uplines: Partial<UserUplines>,
  field: "total" | "verified" | "subscribed",
  maxDepth: number = 15
): void {
  for (let level = 1; level <= maxDepth; level++) {
    const key = getUplineKey(level) as keyof UserUplines;
    const ancestorUid = uplines[key] as string | null;

    if (!ancestorUid) break;

    const statsRef = db.collection(COLLECTIONS.USER_NETWORK_STATS).doc(ancestorUid);
    transaction.update(statsRef, {
      [`level${level}.${field}`]: increment(1),
      updatedAt: serverTimestamp(),
    });
  }
}

/**
 * Update relations when user status changes (verified/subscribed)
 */
export async function updateRelationsOnStatusChange(
  descendantUid: string,
  field: "descendantVerified" | "descendantSubscribed",
  value: boolean
): Promise<void> {
  const relationsQuery = await db
    .collection(COLLECTIONS.USER_RELATIONS)
    .where("descendantUid", "==", descendantUid)
    .get();

  if (relationsQuery.empty) return;

  const batch = db.batch();
  relationsQuery.docs.forEach((doc) => {
    batch.update(doc.ref, { [field]: value });
  });

  await batch.commit();
}

/**
 * Get user uplines document
 */
export async function getUserUplines(uid: string): Promise<UserUplines | null> {
  const uplinesRef = db.collection(COLLECTIONS.USER_UPLINES).doc(uid);
  const doc = await uplinesRef.get();

  if (!doc.exists) return null;
  return doc.data() as UserUplines;
}

/**
 * Get user network stats
 */
export async function getUserNetworkStats(uid: string): Promise<UserNetworkStats | null> {
  const statsRef = db.collection(COLLECTIONS.USER_NETWORK_STATS).doc(uid);
  const doc = await statsRef.get();

  if (!doc.exists) return null;
  return doc.data() as UserNetworkStats;
}

/**
 * Get upline UIDs as array (only non-null values)
 */
export function getUplineUidsArray(uplines: UserUplines, maxDepth: number = 15): string[] {
  const uids: string[] = [];
  for (let level = 1; level <= maxDepth; level++) {
    const key = getUplineKey(level, maxDepth) as keyof UserUplines;
    const uid = uplines[key] as string | null;
    if (uid) uids.push(uid);
    else break;
  }
  return uids;
}

/**
 * Get upline at specific level
 */
export function getUplineAtLevel(uplines: UserUplines, level: number, maxDepth: number = 15): string | null {
  if (level < 1 || level > maxDepth) return null;
  const key = getUplineKey(level, maxDepth) as keyof UserUplines;
  return uplines[key] as string | null;
}

/**
 * Distribute reward points to uplines based on subscription
 * Now checks if each upline is verified — unverified/missing uplines are skipped
 * and their share goes to app funding.
 */
export async function distributeSubscriptionRewards(
  descendantUid: string,
  uplines: UserUplines
): Promise<DistributionResult> {
  const config = await getAppConfig();
  const rewards = new Map<string, number>();
  const undistributed: UndistributedEntry[] = [];

  for (const dist of config.subscription.levelDistribution) {
    const uplineUid = getUplineAtLevel(uplines, dist.level, config.network.maxDepth);

    if (!uplineUid) {
      // Missing upline — log to app funding, continue to next level
      undistributed.push({
        level: dist.level,
        uplineUid: null,
        reason: UNDISTRIBUTED_REASONS.MISSING_UPLINE,
        points: dist.points,
      });
      continue;
    }

    // Check if upline is verified
    const uplineDoc = await db.collection(COLLECTIONS.USERS).doc(uplineUid).get();
    if (!uplineDoc.exists) {
      undistributed.push({
        level: dist.level,
        uplineUid,
        reason: UNDISTRIBUTED_REASONS.MISSING_UPLINE,
        points: dist.points,
      });
      continue;
    }

    const uplineData = uplineDoc.data() as UserDocument;
    if (!uplineData.status.verified) {
      undistributed.push({
        level: dist.level,
        uplineUid,
        reason: UNDISTRIBUTED_REASONS.UNVERIFIED_UPLINE,
        points: dist.points,
      });
      continue;
    }

    rewards.set(uplineUid, dist.points);
  }

  return { rewards, undistributed };
}

/**
 * Distribute reward points to uplines based on verification
 * Now checks if each upline is verified — unverified/missing uplines are skipped
 * and their share goes to app funding.
 */
export async function distributeVerificationRewards(
  descendantUid: string,
  uplines: UserUplines
): Promise<DistributionResult> {
  const config = await getAppConfig();
  const rewards = new Map<string, number>();
  const undistributed: UndistributedEntry[] = [];

  for (const dist of config.verification.levelDistribution) {
    const uplineUid = getUplineAtLevel(uplines, dist.level, config.network.maxDepth);

    if (!uplineUid) {
      // Missing upline — log to app funding, continue to next level
      undistributed.push({
        level: dist.level,
        uplineUid: null,
        reason: UNDISTRIBUTED_REASONS.MISSING_UPLINE,
        points: dist.points,
      });
      continue;
    }

    // Check if upline is verified
    const uplineDoc = await db.collection(COLLECTIONS.USERS).doc(uplineUid).get();
    if (!uplineDoc.exists) {
      undistributed.push({
        level: dist.level,
        uplineUid,
        reason: UNDISTRIBUTED_REASONS.MISSING_UPLINE,
        points: dist.points,
      });
      continue;
    }

    const uplineData = uplineDoc.data() as UserDocument;
    if (!uplineData.status.verified) {
      undistributed.push({
        level: dist.level,
        uplineUid,
        reason: UNDISTRIBUTED_REASONS.UNVERIFIED_UPLINE,
        points: dist.points,
      });
      continue;
    }

    rewards.set(uplineUid, dist.points);
  }

  return { rewards, undistributed };
}

/**
 * Get direct downlines count (level 1 only)
 */
export async function getDirectDownlinesCount(uid: string): Promise<number> {
  const statsRef = db.collection(COLLECTIONS.USER_NETWORK_STATS).doc(uid);
  const doc = await statsRef.get();

  if (!doc.exists) return 0;

  const stats = doc.data() as UserNetworkStats;
  return stats.level1?.total || 0;
}

/**
 * Get total network size (all levels)
 */
export async function getTotalNetworkSize(uid: string): Promise<number> {
  const config = await getAppConfig();
  const maxDepth = config.network.maxDepth;
  const statsRef = db.collection(COLLECTIONS.USER_NETWORK_STATS).doc(uid);
  const doc = await statsRef.get();

  if (!doc.exists) return 0;

  const stats = doc.data() as UserNetworkStats;
  let total = 0;

  for (let level = 1; level <= maxDepth; level++) {
    const levelStats = stats[`level${level}`] as LevelStats;
    if (levelStats) total += levelStats.total;
  }

  return total;
}
