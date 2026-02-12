/**
 * Script to create super admin user
 * Run this once to create the initial super admin account
 * 
 * Usage: npm run create-super-admin
 */

import * as admin from "firebase-admin";
import { COLLECTIONS, USER_ROLES, ACCOUNT_STATES, SUBSCRIPTION_STATUS, RISK_LEVELS } from "../../config/constants";
import { serverTimestamp, getTodayDateString } from "../../utils/helpers";

// Initialize Firebase Admin with service account
// For production, set GOOGLE_APPLICATION_CREDENTIALS environment variable
// Or provide service account key file path
try {
  admin.initializeApp({
    projectId: "shirah-shirahsoft",
  });
} catch (error: any) {
  if (error.code !== "app/duplicate-app") {
    throw error;
  }
}

const db = admin.firestore();

const SUPER_ADMIN_EMAIL = "contact.labibur@gmail.com";
const SUPER_ADMIN_PASSWORD = "sHi22RaH#2820";
const SUPER_ADMIN_INVITE_CODE = "SSHIRAHL"; // Fixed invite code for super admin

const SUPER_ADMIN_DATA = {
  email: SUPER_ADMIN_EMAIL,
  firstName: "Super",
  lastName: "Admin",
  phoneNumber: "+8801700000000", // Update with actual phone
  role: USER_ROLES.SUPER_ADMIN,
};

async function createSuperAdmin() {
  try {
    console.log("🚀 Starting Super Admin creation...");
    console.log("=====================================");

    // Check if user already exists
    let userRecord;
    try {
      userRecord = await admin.auth().getUserByEmail(SUPER_ADMIN_EMAIL);
      console.log("✅ User already exists in Firebase Auth:", userRecord.uid);
    } catch (error: any) {
      if (error.code === "auth/user-not-found") {
        // Create user in Firebase Auth
        console.log("📝 Creating user in Firebase Auth...");
        userRecord = await admin.auth().createUser({
          email: SUPER_ADMIN_EMAIL,
          password: SUPER_ADMIN_PASSWORD,
          displayName: `${SUPER_ADMIN_DATA.firstName} ${SUPER_ADMIN_DATA.lastName}`,
          emailVerified: true,
        });
        console.log("✅ User created in Firebase Auth:", userRecord.uid);
      } else {
        throw error;
      }
    }

    const uid = userRecord.uid;

    // Check if user document exists
    const userDoc = await db.collection(COLLECTIONS.USERS).doc(uid).get();
    
    if (userDoc.exists) {
      console.log("⚠️  User document already exists in Firestore");
      
      // Update to super admin if not already
      const userData = userDoc.data();
      if (userData?.role !== USER_ROLES.SUPER_ADMIN) {
        console.log("🔄 Updating role to super admin...");
        await db.collection(COLLECTIONS.USERS).doc(uid).update({
          role: USER_ROLES.SUPER_ADMIN,
          "meta.updatedAt": serverTimestamp(),
        });
        console.log("✅ Role updated to super admin");
      } else {
        console.log("✅ User is already a super admin");
      }
      
      return; // Skip rest if already exists
    }

    // Create complete user document structure
    console.log("📝 Creating user document in Firestore...");
    
    const userData = {
      // Basic identity
      uid,
      role: USER_ROLES.SUPER_ADMIN,
      
      // Identity section
      identity: {
        firstName: SUPER_ADMIN_DATA.firstName,
        lastName: SUPER_ADMIN_DATA.lastName,
        email: SUPER_ADMIN_EMAIL,
        phone: SUPER_ADMIN_DATA.phoneNumber,
        authProvider: "password",
        photoURL: "",
        coverURL: "",
      },
      
      // Codes section
      codes: {
        inviteCode: SUPER_ADMIN_INVITE_CODE,
        referralCode: uid,
      },
      
      // Network section (no parent for super admin)
      network: {
        parentUid: null,
        joinedVia: "manual",
      },
      
      // Status section
      status: {
        accountState: ACCOUNT_STATES.ACTIVE,
        verified: true,
        subscription: SUBSCRIPTION_STATUS.ACTIVE,
        riskLevel: RISK_LEVELS.NORMAL,
      },
      
      // Wallet section
      wallet: {
        balanceBDT: 0,
        rewardPoints: 0,
        locked: false,
      },
      
      // Permissions section (full access)
      permissions: {
        canPost: true,
        canWithdraw: true,
        canViewCommunity: true,
      },
      
      // Flags section
      flags: {
        isTestUser: false,
      },
      
      // Limits section
      limits: {
        dailyAdsViewed: 0,
        dailyRewardConverted: 0,
        lastLimitReset: getTodayDateString(),
      },
      
      // Meta section
      meta: {
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
        lastLoginAt: null,
        lastActiveAt: null,
      },
      
      // System section
      system: {
        banReason: null,
        suspendUntil: null,
        notes: "Manually created super admin via script",
      },
    };

    await db.collection(COLLECTIONS.USERS).doc(uid).set(userData);
    console.log("✅ User document created");

    // Create invite code document
    console.log("📝 Creating invite code document...");
    await db.collection(COLLECTIONS.INVITE_CODES).doc(SUPER_ADMIN_INVITE_CODE).set({
      uid,
      email: SUPER_ADMIN_EMAIL,
      createdAt: serverTimestamp(),
    });
    console.log("✅ Invite code document created");

    // Create user_uplines document (all null for super admin)
    console.log("📝 Creating user uplines document...");
    const uplinesData: any = {
      maxDepth: 15,
      createdAt: serverTimestamp(),
    };
    for (let i = 1; i <= 15; i++) {
      uplinesData[`u${i}`] = null;
    }
    await db.collection(COLLECTIONS.USER_UPLINES).doc(uid).set(uplinesData);
    console.log("✅ User uplines document created");

    // Create user_network_stats document
    console.log("📝 Creating network stats document...");
    const statsData: any = {
      updatedAt: serverTimestamp(),
    };
    for (let i = 1; i <= 15; i++) {
      statsData[`level${i}`] = {
        total: 0,
        verified: 0,
        subscribed: 0,
      };
    }
    await db.collection(COLLECTIONS.USER_NETWORK_STATS).doc(uid).set(statsData);
    console.log("✅ Network stats document created");

    console.log("\n🎉 Super Admin creation completed successfully!");
    console.log("=====================================");
    console.log("📧 Email:", SUPER_ADMIN_EMAIL);
    console.log("🔑 Password:", SUPER_ADMIN_PASSWORD);
    console.log("🆔 UID:", uid);
    console.log("👤 Role:", USER_ROLES.SUPER_ADMIN);
    console.log("🎫 Invite Code:", SUPER_ADMIN_INVITE_CODE);
    console.log("=====================================");
    console.log("\n📝 IMPORTANT NOTES:");
    console.log("1. Save this invite code: " + SUPER_ADMIN_INVITE_CODE);
    console.log("2. This is the FIRST invite code in the system");
    console.log("3. Share it ONLY with trusted team members");
    console.log("4. Change the password after first login");
    console.log("5. Enable 2FA in Firebase Console");
    console.log("\n✅ You can now login to the admin panel!");
    console.log("=====================================\n");

  } catch (error) {
    console.error("❌ Error creating super admin:", error);
    throw error;
  } finally {
    process.exit(0);
  }
}

// Run the script
createSuperAdmin();
