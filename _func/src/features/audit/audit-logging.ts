/**
 * SHIRAH Cloud Functions - Audit Module
 * Handles all audit logging for sensitive actions
 */

import * as admin from "firebase-admin";
import { COLLECTIONS } from "../../config/constants";
import { AuditLog } from "../../types";
import { serverTimestamp, hashSensitiveData } from "../../utils/helpers";

const db = admin.firestore();

/**
 * Create an audit log entry
 */
export async function createAuditLog(params: {
  actorUid: string;
  actorRole: string;
  action: string;
  targetUid?: string | null;
  targetCollection?: string | null;
  targetDocId?: string | null;
  before?: Record<string, unknown> | null;
  after?: Record<string, unknown> | null;
  metadata?: Record<string, unknown>;
  ipAddress?: string | null;
  device?: string | null;
}): Promise<string> {
  const logRef = db.collection(COLLECTIONS.AUDIT_LOGS).doc();

  const auditLog: Omit<AuditLog, "id" | "timestamp"> & {
    id: string;
    timestamp: FirebaseFirestore.FieldValue;
  } = {
    id: logRef.id,
    actorUid: params.actorUid,
    actorRole: params.actorRole,
    action: params.action,
    targetUid: params.targetUid || null,
    targetCollection: params.targetCollection || null,
    targetDocId: params.targetDocId || null,
    before: params.before || null,
    after: params.after || null,
    metadata: params.metadata || {},
    ipHash: params.ipAddress ? hashSensitiveData(params.ipAddress) : null,
    device: params.device || null,
    timestamp: serverTimestamp(),
  };

  await logRef.set(auditLog);
  return logRef.id;
}

/**
 * Create audit log within a transaction
 */
export function createAuditLogInTransaction(
  transaction: FirebaseFirestore.Transaction,
  params: {
    actorUid: string;
    actorRole: string;
    action: string;
    targetUid?: string | null;
    targetCollection?: string | null;
    targetDocId?: string | null;
    before?: Record<string, unknown> | null;
    after?: Record<string, unknown> | null;
    metadata?: Record<string, unknown>;
    ipAddress?: string | null;
    device?: string | null;
  }
): string {
  const logRef = db.collection(COLLECTIONS.AUDIT_LOGS).doc();

  const auditLog = {
    id: logRef.id,
    actorUid: params.actorUid,
    actorRole: params.actorRole,
    action: params.action,
    targetUid: params.targetUid || null,
    targetCollection: params.targetCollection || null,
    targetDocId: params.targetDocId || null,
    before: params.before || null,
    after: params.after || null,
    metadata: params.metadata || {},
    ipHash: params.ipAddress ? hashSensitiveData(params.ipAddress) : null,
    device: params.device || null,
    timestamp: serverTimestamp(),
  };

  transaction.set(logRef, auditLog);
  return logRef.id;
}

/**
 * Create audit log within a batch
 */
export function createAuditLogInBatch(
  batch: FirebaseFirestore.WriteBatch,
  params: {
    actorUid: string;
    actorRole: string;
    action: string;
    targetUid?: string | null;
    targetCollection?: string | null;
    targetDocId?: string | null;
    before?: Record<string, unknown> | null;
    after?: Record<string, unknown> | null;
    metadata?: Record<string, unknown>;
    ipAddress?: string | null;
    device?: string | null;
  }
): string {
  const logRef = db.collection(COLLECTIONS.AUDIT_LOGS).doc();

  const auditLog = {
    id: logRef.id,
    actorUid: params.actorUid,
    actorRole: params.actorRole,
    action: params.action,
    targetUid: params.targetUid || null,
    targetCollection: params.targetCollection || null,
    targetDocId: params.targetDocId || null,
    before: params.before || null,
    after: params.after || null,
    metadata: params.metadata || {},
    ipHash: params.ipAddress ? hashSensitiveData(params.ipAddress) : null,
    device: params.device || null,
    timestamp: serverTimestamp(),
  };

  batch.set(logRef, auditLog);
  return logRef.id;
}

/**
 * Get audit logs for a specific user
 */
export async function getAuditLogsForUser(
  targetUid: string,
  limit: number = 50
): Promise<AuditLog[]> {
  const snapshot = await db
    .collection(COLLECTIONS.AUDIT_LOGS)
    .where("targetUid", "==", targetUid)
    .orderBy("timestamp", "desc")
    .limit(limit)
    .get();

  return snapshot.docs.map((doc) => doc.data() as AuditLog);
}

/**
 * Get audit logs by action type
 */
export async function getAuditLogsByAction(
  action: string,
  limit: number = 50
): Promise<AuditLog[]> {
  const snapshot = await db
    .collection(COLLECTIONS.AUDIT_LOGS)
    .where("action", "==", action)
    .orderBy("timestamp", "desc")
    .limit(limit)
    .get();

  return snapshot.docs.map((doc) => doc.data() as AuditLog);
}

/**
 * Get audit logs by actor
 */
export async function getAuditLogsByActor(
  actorUid: string,
  limit: number = 50
): Promise<AuditLog[]> {
  const snapshot = await db
    .collection(COLLECTIONS.AUDIT_LOGS)
    .where("actorUid", "==", actorUid)
    .orderBy("timestamp", "desc")
    .limit(limit)
    .get();

  return snapshot.docs.map((doc) => doc.data() as AuditLog);
}
