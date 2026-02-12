/**
 * SHIRAH Cloud Functions - Permissions Module
 * Handles RBAC, admin permissions, and role management
 */

import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import {
  COLLECTIONS,
  USER_ROLES,
  AUDIT_ACTIONS,
  REGION,
} from "../../config/constants";
import {
  AdminPermissions,
  PermissionTemplate,
  ApiResponse,
} from "../../types";
import { serverTimestamp } from "../../utils/helpers";
import {
  validateAuthenticated,
  validateMinimumRole,
  validateAdminPermission,
  validateRoleChange,
  validatePermissionFormat,
} from "../../utils/validators";
import { createAuditLog } from "../audit/audit-logging";
import { getUserByUid } from "../users/user-management";

const db = admin.firestore();

/**
 * Get admin permissions for a user
 */
export async function getAdminPermissions(
  uid: string
): Promise<Record<string, boolean>> {
  const permissionsRef = db.collection(COLLECTIONS.ADMIN_PERMISSIONS).doc(uid);
  const doc = await permissionsRef.get();

  if (!doc.exists) return {};

  const data = doc.data() as AdminPermissions;
  return data.permissions || {};
}

/**
 * Check if user has specific permission
 */
export async function hasPermission(
  uid: string,
  permission: string
): Promise<boolean> {
  const user = await getUserByUid(uid);
  if (!user) return false;

  // SuperAdmin has all permissions
  if (user.role === USER_ROLES.SUPER_ADMIN) return true;

  // Check if user is admin or higher
  if (
    user.role !== USER_ROLES.ADMIN &&
    user.role !== USER_ROLES.MODERATOR &&
    user.role !== USER_ROLES.SUPPORT
  ) {
    return false;
  }

  const permissions = await getAdminPermissions(uid);
  return permissions[permission] === true;
}

/**
 * Check multiple permissions (AND logic)
 */
export async function hasAllPermissions(
  uid: string,
  requiredPermissions: string[]
): Promise<boolean> {
  const user = await getUserByUid(uid);
  if (!user) return false;

  if (user.role === USER_ROLES.SUPER_ADMIN) return true;

  const permissions = await getAdminPermissions(uid);

  for (const perm of requiredPermissions) {
    if (!permissions[perm]) return false;
  }

  return true;
}

/**
 * Check multiple permissions (OR logic)
 */
export async function hasAnyPermission(
  uid: string,
  requiredPermissions: string[]
): Promise<boolean> {
  const user = await getUserByUid(uid);
  if (!user) return false;

  if (user.role === USER_ROLES.SUPER_ADMIN) return true;

  const permissions = await getAdminPermissions(uid);

  for (const perm of requiredPermissions) {
    if (permissions[perm]) return true;
  }

  return false;
}

/**
 * Grant permissions to a user
 */
export async function grantPermissions(
  targetUid: string,
  permissions: string[],
  grantedBy: string
): Promise<void> {
  const permissionsRef = db.collection(COLLECTIONS.ADMIN_PERMISSIONS).doc(targetUid);
  const doc = await permissionsRef.get();

  const currentPermissions: Record<string, boolean> = doc.exists
    ? (doc.data() as AdminPermissions).permissions || {}
    : {};

  // Add new permissions
  for (const perm of permissions) {
    validatePermissionFormat(perm);
    currentPermissions[perm] = true;
  }

  await permissionsRef.set({
    uid: targetUid,
    permissions: currentPermissions,
    assignedBy: grantedBy,
    updatedAt: serverTimestamp(),
  });

  await createAuditLog({
    actorUid: grantedBy,
    actorRole: USER_ROLES.ADMIN,
    action: AUDIT_ACTIONS.PERMISSION_GRANT,
    targetUid,
    targetCollection: COLLECTIONS.ADMIN_PERMISSIONS,
    metadata: { permissionsGranted: permissions },
  });
}

/**
 * Revoke permissions from a user
 */
export async function revokePermissions(
  targetUid: string,
  permissions: string[],
  revokedBy: string
): Promise<void> {
  const permissionsRef = db.collection(COLLECTIONS.ADMIN_PERMISSIONS).doc(targetUid);
  const doc = await permissionsRef.get();

  if (!doc.exists) return;

  const currentPermissions = (doc.data() as AdminPermissions).permissions || {};

  // Remove permissions
  for (const perm of permissions) {
    delete currentPermissions[perm];
  }

  await permissionsRef.update({
    permissions: currentPermissions,
    assignedBy: revokedBy,
    updatedAt: serverTimestamp(),
  });

  await createAuditLog({
    actorUid: revokedBy,
    actorRole: USER_ROLES.ADMIN,
    action: AUDIT_ACTIONS.PERMISSION_REVOKE,
    targetUid,
    targetCollection: COLLECTIONS.ADMIN_PERMISSIONS,
    metadata: { permissionsRevoked: permissions },
  });
}

/**
 * Cloud Function: Grant permissions to user (Admin only)
 */
export const grantUserPermissions = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<{
    targetUid: string;
    permissions: string[];
  }>): Promise<ApiResponse> => {
    const actorUid = validateAuthenticated(request.auth);
    const { targetUid, permissions } = request.data;

    if (!targetUid || !permissions || permissions.length === 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "targetUid and permissions are required"
      );
    }

    const actor = await getUserByUid(actorUid);
    if (!actor) {
      throw new functions.https.HttpsError("not-found", "Actor not found");
    }

    // Only superAdmin and admin can grant permissions
    validateMinimumRole(actor.role, USER_ROLES.ADMIN);

    // If not superAdmin, check if actor has permission to grant
    if (actor.role !== USER_ROLES.SUPER_ADMIN) {
      const actorPermissions = await getAdminPermissions(actorUid);
      validateAdminPermission(actorPermissions, "permission.grant");
    }

    // Validate target exists
    const target = await getUserByUid(targetUid);
    if (!target) {
      throw new functions.https.HttpsError("not-found", "Target user not found");
    }

    // Validate all permission formats
    permissions.forEach(validatePermissionFormat);

    await grantPermissions(targetUid, permissions, actorUid);

    return {
      success: true,
      message: `Granted ${permissions.length} permissions to user`,
    };
  }
);

/**
 * Cloud Function: Revoke permissions from user (Admin only)
 */
export const revokeUserPermissions = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<{
    targetUid: string;
    permissions: string[];
  }>): Promise<ApiResponse> => {
    const actorUid = validateAuthenticated(request.auth);
    const { targetUid, permissions } = request.data;

    if (!targetUid || !permissions || permissions.length === 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "targetUid and permissions are required"
      );
    }

    const actor = await getUserByUid(actorUid);
    if (!actor) {
      throw new functions.https.HttpsError("not-found", "Actor not found");
    }

    validateMinimumRole(actor.role, USER_ROLES.ADMIN);

    if (actor.role !== USER_ROLES.SUPER_ADMIN) {
      const actorPermissions = await getAdminPermissions(actorUid);
      validateAdminPermission(actorPermissions, "permission.revoke");
    }

    await revokePermissions(targetUid, permissions, actorUid);

    return {
      success: true,
      message: `Revoked ${permissions.length} permissions from user`,
    };
  }
);

/**
 * Cloud Function: Change user role (Admin only)
 */
export const changeUserRole = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<{
    targetUid: string;
    newRole: string;
  }>): Promise<ApiResponse> => {
    const actorUid = validateAuthenticated(request.auth);
    const { targetUid, newRole } = request.data;

    if (!targetUid || !newRole) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "targetUid and newRole are required"
      );
    }

    const actor = await getUserByUid(actorUid);
    if (!actor) {
      throw new functions.https.HttpsError("not-found", "Actor not found");
    }

    validateMinimumRole(actor.role, USER_ROLES.ADMIN);

    const target = await getUserByUid(targetUid);
    if (!target) {
      throw new functions.https.HttpsError("not-found", "Target user not found");
    }

    validateRoleChange(target.role, newRole, actor.role);

    // Can't change own role
    if (actorUid === targetUid) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Cannot change your own role"
      );
    }

    const userRef = db.collection(COLLECTIONS.USERS).doc(targetUid);
    const oldRole = target.role;

    await userRef.update({
      role: newRole,
      "meta.updatedAt": serverTimestamp(),
    });

    await createAuditLog({
      actorUid,
      actorRole: actor.role,
      action: AUDIT_ACTIONS.ROLE_CHANGE,
      targetUid,
      before: { role: oldRole },
      after: { role: newRole },
    });

    return {
      success: true,
      message: `User role changed from ${oldRole} to ${newRole}`,
    };
  }
);

/**
 * Cloud Function: Get user permissions (Admin only)
 */
export const getUserPermissions = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<{ targetUid: string }>): Promise<ApiResponse<{
    role: string;
    permissions: Record<string, boolean>;
  }>> => {
    const actorUid = validateAuthenticated(request.auth);
    const { targetUid } = request.data;

    const actor = await getUserByUid(actorUid);
    if (!actor) {
      throw new functions.https.HttpsError("not-found", "Actor not found");
    }

    validateMinimumRole(actor.role, USER_ROLES.SUPPORT);

    const target = await getUserByUid(targetUid);
    if (!target) {
      throw new functions.https.HttpsError("not-found", "Target user not found");
    }

    const permissions = await getAdminPermissions(targetUid);

    return {
      success: true,
      message: "Permissions retrieved",
      data: {
        role: target.role,
        permissions,
      },
    };
  }
);

/**
 * Cloud Function: Get my permissions
 */
export const getMyPermissions = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest): Promise<ApiResponse<{
    role: string;
    permissions: Record<string, boolean>;
    isSuperAdmin: boolean;
  }>> => {
    const uid = validateAuthenticated(request.auth);

    const user = await getUserByUid(uid);
    if (!user) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }

    const permissions = await getAdminPermissions(uid);

    return {
      success: true,
      message: "Permissions retrieved",
      data: {
        role: user.role,
        permissions,
        isSuperAdmin: user.role === USER_ROLES.SUPER_ADMIN,
      },
    };
  }
);

/**
 * Create permission template
 */
export async function createPermissionTemplate(
  name: string,
  description: string,
  permissions: string[],
  createdBy: string
): Promise<string> {
  const templateRef = db.collection(COLLECTIONS.PERMISSION_TEMPLATES).doc();

  const template: Omit<PermissionTemplate, "createdAt"> & {
    createdAt: FirebaseFirestore.FieldValue;
  } = {
    id: templateRef.id,
    name,
    description,
    permissions,
    createdBy,
    createdAt: serverTimestamp(),
  };

  await templateRef.set(template);
  return templateRef.id;
}

/**
 * Apply permission template to user
 */
export async function applyPermissionTemplate(
  templateId: string,
  targetUid: string,
  appliedBy: string
): Promise<void> {
  const templateRef = db.collection(COLLECTIONS.PERMISSION_TEMPLATES).doc(templateId);
  const templateDoc = await templateRef.get();

  if (!templateDoc.exists) {
    throw new functions.https.HttpsError("not-found", "Template not found");
  }

  const template = templateDoc.data() as PermissionTemplate;
  await grantPermissions(targetUid, template.permissions, appliedBy);
}

/**
 * Get all permission templates
 */
export async function getPermissionTemplates(): Promise<PermissionTemplate[]> {
  const snapshot = await db.collection(COLLECTIONS.PERMISSION_TEMPLATES).get();
  return snapshot.docs.map((doc) => doc.data() as PermissionTemplate);
}
