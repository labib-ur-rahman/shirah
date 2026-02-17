/**
 * SHIRAH Cloud Functions - Invite Codes Module
 * Handles invite code generation, validation, and lookup
 */

import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { COLLECTIONS } from "../../config/constants";
import { getAppConfig } from "../../config/dynamic-config";
import { InviteCodeDocument } from "../../types";
import {
  generateInviteCode,
  serverTimestamp,
  retryWithBackoff,
} from "../../utils/helpers";

const db = admin.firestore();

/**
 * Generate a unique invite code with collision check
 * Retries up to 5 times if collision detected
 */
export async function generateUniqueInviteCode(
  uid: string,
  email: string
): Promise<string> {
  const maxAttempts = 5;
  const config = await getAppConfig();

  for (let attempt = 0; attempt < maxAttempts; attempt++) {
    const inviteCode = generateInviteCode(config.inviteCode);
    const inviteCodeRef = db.collection(COLLECTIONS.INVITE_CODES).doc(inviteCode);

    try {
      // Try to create the invite code document
      // This will fail if the code already exists (using transaction)
      await db.runTransaction(async (transaction) => {
        const doc = await transaction.get(inviteCodeRef);

        if (doc.exists) {
          throw new Error("COLLISION");
        }

        const inviteCodeData: Omit<InviteCodeDocument, "createdAt"> & {
          createdAt: FirebaseFirestore.FieldValue;
        } = {
          uid,
          email,
          createdAt: serverTimestamp(),
        };

        transaction.set(inviteCodeRef, inviteCodeData);
      });

      return inviteCode;
    } catch (error) {
      if ((error as Error).message === "COLLISION") {
        // Retry with a new code
        continue;
      }
      throw error;
    }
  }

  throw new functions.https.HttpsError(
    "internal",
    "Failed to generate unique invite code after multiple attempts"
  );
}

/**
 * Validate and lookup invite code
 * Returns the UID of the invite code owner (parent)
 */
export async function validateAndLookupInviteCode(
  inviteCode: string
): Promise<string> {
  const inviteCodeRef = db.collection(COLLECTIONS.INVITE_CODES).doc(inviteCode);
  const doc = await inviteCodeRef.get();

  if (!doc.exists) {
    throw new functions.https.HttpsError(
      "not-found",
      "Invalid invite code"
    );
  }

  const data = doc.data() as InviteCodeDocument;
  return data.uid;
}

/**
 * Check if invite code exists
 */
export async function inviteCodeExists(inviteCode: string): Promise<boolean> {
  const inviteCodeRef = db.collection(COLLECTIONS.INVITE_CODES).doc(inviteCode);
  const doc = await inviteCodeRef.get();
  return doc.exists;
}

/**
 * Get invite code document
 */
export async function getInviteCodeDocument(
  inviteCode: string
): Promise<InviteCodeDocument | null> {
  const inviteCodeRef = db.collection(COLLECTIONS.INVITE_CODES).doc(inviteCode);
  const doc = await inviteCodeRef.get();

  if (!doc.exists) {
    return null;
  }

  return doc.data() as InviteCodeDocument;
}

/**
 * Delete invite code (for admin cleanup if needed)
 */
export async function deleteInviteCode(inviteCode: string): Promise<void> {
  const inviteCodeRef = db.collection(COLLECTIONS.INVITE_CODES).doc(inviteCode);
  await inviteCodeRef.delete();
}

/**
 * Generate invite code with retry logic
 */
export async function generateInviteCodeWithRetry(
  uid: string,
  email: string
): Promise<string> {
  return retryWithBackoff(
    () => generateUniqueInviteCode(uid, email),
    3,
    500
  );
}

/**
 * Reserve invite code in transaction (for signup flow)
 */
export function reserveInviteCodeInTransaction(
  transaction: FirebaseFirestore.Transaction,
  inviteCode: string,
  uid: string,
  email: string
): void {
  const inviteCodeRef = db.collection(COLLECTIONS.INVITE_CODES).doc(inviteCode);

  const inviteCodeData = {
    uid,
    email,
    createdAt: serverTimestamp(),
  };

  transaction.set(inviteCodeRef, inviteCodeData);
}
