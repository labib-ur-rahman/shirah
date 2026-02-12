/**
 * SHIRAH Cloud Functions - Configuration Management
 * =====================================================
 *
 * Admin-only callable functions to seed and update
 * the `configurations/app_settings` document in Firestore.
 *
 * After any update, the in-memory config cache is cleared so
 * the next Cloud Function invocation reads fresh data.
 */

import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { REGION, AUDIT_ACTIONS, USER_ROLES } from "../../config/constants";
import {
  CONFIG_COLLECTION,
  CONFIG_DOC_ID,
  DEFAULT_CONFIG,
  clearConfigCache,
  AppConfig,
} from "../../config/dynamic-config";
import { serverTimestamp } from "../../utils/helpers";
import {
  validateAuthenticated,
  validateMinimumRole,
} from "../../utils/validators";
import { getUserByUid } from "../users/user-management";
import { createAuditLog } from "../audit/audit-logging";

const db = admin.firestore();

// ============================================
// SEED CONFIGURATION
// ============================================

/**
 * Cloud Function: Seed the configurations document with defaults.
 * Safe to call multiple times — only writes if doc does NOT exist.
 *
 * Requires: superAdmin
 */
export const seedConfigurations = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest): Promise<{
    success: boolean;
    message: string;
    seeded: boolean;
  }> => {
    const uid = validateAuthenticated(request.auth);
    const user = await getUserByUid(uid);
    if (!user) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }
    validateMinimumRole(user.role, USER_ROLES.SUPER_ADMIN);

    const docRef = db.collection(CONFIG_COLLECTION).doc(CONFIG_DOC_ID);
    const doc = await docRef.get();

    if (doc.exists) {
      return {
        success: true,
        message: "Configuration already exists. No changes made.",
        seeded: false,
      };
    }

    // Write default config + metadata
    await docRef.set({
      ...DEFAULT_CONFIG,
      _meta: {
        createdAt: serverTimestamp(),
        createdBy: uid,
        updatedAt: serverTimestamp(),
        updatedBy: uid,
        version: 1,
      },
    });

    clearConfigCache();

    await createAuditLog({
      actorUid: uid,
      actorRole: user.role,
      action: AUDIT_ACTIONS.ADMIN_ACTION,
      targetUid: uid,
      metadata: { operation: "seed_configurations" },
    });

    return {
      success: true,
      message: "Configuration seeded with default values.",
      seeded: true,
    };
  }
);

// ============================================
// UPDATE CONFIGURATION
// ============================================

/**
 * Cloud Function: Update one or more configuration sections.
 *
 * Accepts a partial `AppConfig` object. Only the keys provided
 * are merged / overwritten; other sections remain unchanged.
 *
 * Example payload:
 * ```json
 * {
 *   "updates": {
 *     "wallet": { "minWithdrawalBDT": 200 },
 *     "ads": { "maxDailyAds": 25, "pointsPerAd": 35 }
 *   }
 * }
 * ```
 *
 * Requires: superAdmin
 */
export const updateAppConfig = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<{
    updates: Partial<AppConfig>;
  }>): Promise<{
    success: boolean;
    message: string;
    updatedSections: string[];
  }> => {
    const uid = validateAuthenticated(request.auth);
    const user = await getUserByUid(uid);
    if (!user) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }
    validateMinimumRole(user.role, USER_ROLES.SUPER_ADMIN);

    const { updates } = request.data;
    if (!updates || typeof updates !== "object" || Object.keys(updates).length === 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "updates object is required and must not be empty"
      );
    }

    // Validate only known sections are provided
    const validSections: (keyof AppConfig)[] = [
      "network", "inviteCode", "rewardPoints", "ads",
      "streak", "subscription", "verification", "wallet",
    ];
    const providedSections = Object.keys(updates);
    const invalidSections = providedSections.filter(
      (s) => !validSections.includes(s as keyof AppConfig)
    );
    if (invalidSections.length > 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        `Unknown configuration sections: ${invalidSections.join(", ")}`
      );
    }

    const docRef = db.collection(CONFIG_COLLECTION).doc(CONFIG_DOC_ID);
    const existingDoc = await docRef.get();

    if (!existingDoc.exists) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Configuration has not been seeded yet. Call seedConfigurations first."
      );
    }

    // Build flat merge-safe update payload
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const updatePayload: Record<string, any> = {};
    for (const section of providedSections) {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const sectionData = (updates as Record<string, any>)[section];
      if (typeof sectionData === "object" && !Array.isArray(sectionData)) {
        // Merge individual fields within the section
        for (const [key, value] of Object.entries(sectionData)) {
          updatePayload[`${section}.${key}`] = value;
        }
      } else {
        // Replace the whole section (e.g., arrays)
        updatePayload[section] = sectionData;
      }
    }

    // Add metadata
    updatePayload["_meta.updatedAt"] = serverTimestamp();
    updatePayload["_meta.updatedBy"] = uid;
    updatePayload["_meta.version"] = admin.firestore.FieldValue.increment(1);

    await docRef.update(updatePayload);

    // Clear cache so next invocation gets fresh data
    clearConfigCache();

    await createAuditLog({
      actorUid: uid,
      actorRole: user.role,
      action: AUDIT_ACTIONS.ADMIN_ACTION,
      targetUid: uid,
      metadata: {
        operation: "update_app_config",
        updatedSections: providedSections,
        updates,
      },
    });

    return {
      success: true,
      message: `Configuration updated: ${providedSections.join(", ")}`,
      updatedSections: providedSections,
    };
  }
);

// ============================================
// GET CONFIGURATION (Admin-readable)
// ============================================

/**
 * Cloud Function: Get the current configuration.
 *
 * Requires: admin or higher
 */
export const getAppConfigAdmin = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest): Promise<{
    success: boolean;
    message: string;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    data: Record<string, any>;
  }> => {
    const uid = validateAuthenticated(request.auth);
    const user = await getUserByUid(uid);
    if (!user) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }
    validateMinimumRole(user.role, USER_ROLES.ADMIN);

    const docRef = db.collection(CONFIG_COLLECTION).doc(CONFIG_DOC_ID);
    const doc = await docRef.get();

    if (!doc.exists) {
      return {
        success: true,
        message: "Configuration not seeded yet. Showing defaults.",
        data: DEFAULT_CONFIG as unknown as Record<string, unknown>,
      };
    }

    return {
      success: true,
      message: "Current configuration",
      data: doc.data()!,
    };
  }
);
