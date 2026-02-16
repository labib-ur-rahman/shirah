# SuperAdmin Setup Guide

## 🚨 Critical Issue Fixed

The authentication error "User must be authenticated" has been fixed in `SessionController`. The following changes were made:

### Changes to `session_controller.dart`:

1. **Added auth state validation**: Before loading user data, now checks if user is still authenticated
2. **Added delay before data load**: 300ms delay ensures Firebase Auth token is ready
3. **Graceful profile failure handling**: If user profile doesn't exist, signs out and shows error message
4. **SuperAdmin permissions bypass**: SuperAdmin role no longer attempts to fetch permissions (they bypass all checks anyway)
5. **Better error handling**: All API calls wrapped in try-catch with user-friendly error messages

---

## 📋 Complete Setup Checklist

To get your SuperAdmin account working, you need to create the required Firestore documents:

### ✅ Required Documents

1. **User Profile** (`users/{your-uid}`)
2. **App Configuration** (`configurations/app_settings`)
3. **Permission Registry** (`permissions/{permission-id}`) — Multiple documents

### ⚠️ Optional Documents

1. **Admin Permissions** (`admin_permissions/{your-uid}`) — Not needed for SuperAdmin, they bypass all checks

---

## 🔑 Step 1: Get Your Firebase Auth UID

1. Open your app and sign in with Google
2. Check the Flutter logs/console for your UID
3. OR go to Firebase Console → Authentication → Users → Copy your UID

Example UID: `NIh7sRnCVZOMQsOAj8k5apaYZ5F3`

---

## 📝 Step 2: Create SuperAdmin User Document

### Via Firebase Console (Easiest):

1. Go to Firebase Console → Firestore Database
2. Navigate to `users` collection (create if doesn't exist)
3. Click **Add Document**
4. Set Document ID = Your Firebase Auth UID
5. Add the following fields:

```json
{
  "uid": "YOUR_FIREBASE_AUTH_UID",
  "role": "superAdmin",
  "identity": {
    "firstName": "Your First Name",
    "lastName": "Your Last Name",
    "email": "your-email@gmail.com",
    "phone": "01XXXXXXXXX",
    "authProvider": "google",
    "photoURL": "https://lh3.googleusercontent.com/...",
    "coverURL": ""
  },
  "codes": {
    "inviteCode": "SSHIRAHL",
    "referralCode": "NIh7sRnCVZOMQsOAj8k5apaYZ5F3"
  },
  "network": {
    "parentUid": null,
    "joinedVia": "manual"
  },
  "status": {
    "accountState": "active",
    "verified": true,
    "subscription": "active",
    "riskLevel": "normal"
  },
  "wallet": {
    "balanceBDT": 0,
    "rewardPoints": 0,
    "locked": false
  },
  "permissions": {
    "canPost": true,
    "canWithdraw": true,
    "canViewCommunity": true
  },
  "flags": {
    "isTestUser": false
  },
  "limits": {
    "dailyAdsViewed": 0,
    "dailyRewardConverted": 0,
    "lastLimitReset": "2025-01-01"
  },
  "meta": {
    "createdAt": "2025-01-15T10:00:00Z",
    "updatedAt": "2025-01-15T10:00:00Z",
    "lastLoginAt": null,
    "lastActiveAt": null
  },
  "system": {
    "banReason": null,
    "suspendUntil": null,
    "notes": "System SuperAdmin - Full Access"
  }
}
```

### Important Notes:

- Replace `YOUR_FIREBASE_AUTH_UID` with your actual UID (in 2 places)
- Replace `Your First Name`, `Your Last Name`, `your-email@gmail.com` with your actual info
- Replace `01XXXXXXXXX` with your Bangladesh phone number (11 digits starting with 01)
- Replace `photoURL` with your Google profile photo URL (get it from Firebase Auth console)
- Change `createdAt` and `updatedAt` to current timestamp

---

## ⚙️ Step 3: Create App Configuration Document

This document contains all app business logic settings (limits, rates, etc.)

### Via Firebase Console:

1. Navigate to `configurations` collection (create if doesn't exist)
2. Create document with ID = `app_settings`
3. Add the following fields (exact structure from `firestore_database_structure.md`):

```json
{
  "network": {
    "maxDepth": 15,
    "verificationDepth": 5
  },
  "inviteCode": {
    "prefix": "S",
    "suffix": "L",
    "randomLength": 6,
    "charset": "ABCDEFGHJKMNPQRSTUVWXYZ23456789",
    "totalLength": 8
  },
  "rewardPoints": {
    "conversionRate": 100,
    "minConversion": 1000,
    "maxDailyConversions": 2,
    "maxWeeklyConversions": 10,
    "conversionFeePercent": 5
  },
  "ads": {
    "maxDailyAds": 20,
    "pointsPerAd": 30,
    "baseDailyPoints": 600
  },
  "streak": {
    "multipliers": {
      "1": 1.0,
      "3": 1.2,
      "7": 1.5,
      "14": 2.0,
      "21": 2.5,
      "28": 3.0
    },
    "maxMultiplier": 3.0
  },
  "subscription": {
    "priceBDT": 400,
    "rewardDistributedBDT": 240,
    "totalRewardPoints": 24000,
    "levelDistribution": [
      {"level": 1, "percent": 25, "points": 6000},
      {"level": 2, "percent": 15, "points": 3600},
      {"level": 3, "percent": 10, "points": 2400},
      {"level": 4, "percent": 8, "points": 1920},
      {"level": 5, "percent": 7, "points": 1680},
      {"level": 6, "percent": 6, "points": 1440},
      {"level": 7, "percent": 5, "points": 1200},
      {"level": 8, "percent": 4, "points": 960},
      {"level": 9, "percent": 4, "points": 960},
      {"level": 10, "percent": 3, "points": 720},
      {"level": 11, "percent": 3, "points": 720},
      {"level": 12, "percent": 2, "points": 480},
      {"level": 13, "percent": 2, "points": 480},
      {"level": 14, "percent": 1.5, "points": 360},
      {"level": 15, "percent": 1.5, "points": 360}
    ]
  },
  "verification": {
    "priceBDT": 250,
    "rewardDistributedBDT": 125,
    "totalRewardPoints": 12500,
    "levelDistribution": [
      {"level": 1, "percent": 40, "points": 5000},
      {"level": 2, "percent": 25, "points": 3125},
      {"level": 3, "percent": 15, "points": 1875},
      {"level": 4, "percent": 10, "points": 1250},
      {"level": 5, "percent": 10, "points": 1250}
    ]
  },
  "wallet": {
    "minWithdrawalBDT": 100,
    "withdrawalFeePer1000": 20
  },
  "_meta": {
    "createdAt": "2025-02-14T10:00:00Z",
    "createdBy": "YOUR_UID",
    "updatedAt": "2025-02-14T10:00:00Z",
    "updatedBy": "YOUR_UID",
    "version": 1
  }
}
```

**Important:** Replace `YOUR_UID` with your actual Firebase Auth UID (in 2 places) and update timestamps to current date/time.

---

## 🔐 Step 4: Create Permission Registry (Optional but Recommended)

These are the master permission definitions. Create multiple documents in the `permissions` collection:

### Via Firebase Console:

1. Navigate to `permissions` collection (create if doesn't exist)
2. Create the following documents:

#### Document ID: `users_view`
```json
{
  "id": "users_view",
  "name": "View Users",
  "category": "users",
  "description": "Can view user list",
  "createdBy": "YOUR_UID",
  "createdAt": "2025-01-15T10:00:00Z"
}
```

#### Document ID: `users_manage`
```json
{
  "id": "users_manage",
  "name": "Manage Users",
  "category": "users",
  "description": "Can edit, suspend, ban users",
  "createdBy": "YOUR_UID",
  "createdAt": "2025-01-15T10:00:00Z"
}
```

#### Document ID: `posts_moderate`
```json
{
  "id": "posts_moderate",
  "name": "Moderate Posts",
  "category": "posts",
  "description": "Can approve, reject, delete posts",
  "createdBy": "YOUR_UID",
  "createdAt": "2025-01-15T10:00:00Z"
}
```

#### Document ID: `wallet_manage`
```json
{
  "id": "wallet_manage",
  "name": "Manage Wallets",
  "category": "wallet",
  "description": "Can view and manage all wallets",
  "createdBy": "YOUR_UID",
  "createdAt": "2025-01-15T10:00:00Z"
}
```

#### Document ID: `withdrawals_process`
```json
{
  "id": "withdrawals_process",
  "name": "Process Withdrawals",
  "category": "withdrawals",
  "description": "Can approve/reject withdrawal requests",
  "createdBy": "YOUR_UID",
  "createdAt": "2025-01-15T10:00:00Z"
}
```

#### Document ID: `config_manage`
```json
{
  "id": "config_manage",
  "name": "Manage Configuration",
  "category": "config",
  "description": "Can edit app configuration",
  "createdBy": "YOUR_UID",
  "createdAt": "2025-01-15T10:00:00Z"
}
```

#### Document ID: `permissions_manage`
```json
{
  "id": "permissions_manage",
  "name": "Manage Permissions",
  "category": "permissions",
  "description": "Can assign permissions to admins",
  "createdBy": "YOUR_UID",
  "createdAt": "2025-01-15T10:00:00Z"
}
```

#### Document ID: `audit_view`
```json
{
  "id": "audit_view",
  "name": "View Audit Logs",
  "category": "audit",
  "description": "Can view system audit logs",
  "createdBy": "YOUR_UID",
  "createdAt": "2025-01-15T10:00:00Z"
}
```

---

## 🔥 Step 5: Deploy Cloud Functions

Your Cloud Functions must be deployed to handle backend operations. Make sure you have:

1. **Installed Firebase CLI**: `npm install -g firebase-tools`
2. **Logged in**: `firebase login`
3. **Deployed functions from your project root**:

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

### Required Cloud Functions:

- `getMyPermissions` — Fetches admin permissions (with SuperAdmin bypass)
- `getUserProfile` — Fetches user profile from Firestore
- `updateUserProfile` — Updates user profile
- `getUserList` — Lists users with pagination
- `updateUserStatus` — Updates user account state
- `getWalletTransactions` — Fetches wallet transaction history
- `processWithdrawal` — Processes withdrawal requests

Check your `functions/src/` folder to ensure these are implemented.

---

## 🧪 Step 6: Test the Setup

1. **Clear app data** (or uninstall/reinstall)
2. **Sign in with Google** using your SuperAdmin email
3. You should now see:
   - ✅ Dashboard loads successfully
   - ✅ Your name and role badge in app bar
   - ✅ All 12 admin navigation tiles visible (SuperAdmin sees everything)
   - ✅ No authentication errors

4. **Test sign-out**:
   - Click your profile avatar → Sign Out
   - Should navigate to login screen without errors

5. **Test re-login**:
   - Sign in again
   - Should load dashboard instantly

---

## ❌ Common Issues & Fixes

### Issue 1: "User must be authenticated" error
**Fixed in this update.** SessionController now checks auth state before API calls.

### Issue 2: "User profile not found"
**Solution**: Create the `users/{uid}` document following Step 2.

### Issue 3: "Cloud Function failed"
**Solution**: Deploy Cloud Functions using Step 5.

### Issue 4: Can't see any navigation tiles
**Solution**: Check that your user document has `role: "superAdmin"` (case-sensitive).

### Issue 5: App crashes on sign-out
**Solution**: Update to latest code (SessionController changes).

---

## 📚 Required Firestore Collections Summary

| Collection | Document ID | Required? | Purpose |
|---|---|---|---|
| `users` | `{your-uid}` | ✅ YES | Your SuperAdmin profile |
| `configurations` | `app_settings` | ✅ YES | App business rules |
| `permissions` | `{permission-id}` | ⚠️ Recommended | Master permission registry (8 docs) |
| `admin_permissions` | `{admin-uid}` | ❌ NO | Not needed for SuperAdmin |
| `audit_logs` | Auto-generated | ❌ NO | Created automatically |
| `invite_codes` | Auto-generated | ❌ NO | Created when new users join |
| `wallet_transactions` | Auto-generated | ❌ NO | Created when wallet used |
| `posts` | Auto-generated | ❌ NO | Created by users |
| `jobs` | Auto-generated | ❌ NO | Created by users |

---

## 🚀 Quick Setup Script (Alternative Method)

If you prefer to seed the database programmatically, you can create a Cloud Function or Flutter script to initialize all required documents. This is faster but requires coding:

### Option A: Cloud Function (Recommended)

Create a one-time setup function:

```typescript
// functions/src/setup/seedDatabase.ts
export const seedSuperAdmin = functions
  .region('asia-south1')
  .https.onCall(async (data, context) => {
    // Check if caller is authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be signed in');
    }

    const uid = context.auth.uid;
    const email = context.auth.token.email || '';
    const displayName = context.auth.token.name || 'Super Admin';
    const photoURL = context.auth.token.picture || '';

    // Create user document
    await admin.firestore().collection('users').doc(uid).set({
      uid,
      role: 'superAdmin',
      identity: {
        firstName: displayName.split(' ')[0],
        lastName: displayName.split(' ').slice(1).join(' ') || 'Admin',
        email,
        phone: '01XXXXXXXXX', // Replace manually
        authProvider: 'google',
        photoURL,
        coverURL: '',
      },
      codes: {
        inviteCode: 'SADMIN01',
        referralCode: uid,
      },
      network: {
        parentUid: null,
        joinedVia: 'manual',
      },
      status: {
        accountState: 'active',
        verified: true,
        subscription: 'active',
        riskLevel: 'normal',
      },
      wallet: {
        balanceBDT: 0,
        rewardPoints: 0,
        locked: false,
      },
      permissions: {
        canPost: true,
        canWithdraw: true,
        canViewCommunity: true,
      },
      flags: {
        isTestUser: false,
      },
      limits: {
        dailyAdsViewed: 0,
        dailyRewardConverted: 0,
        lastLimitReset: new Date().toISOString().split('T')[0],
      },
      meta: {
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        lastLoginAt: null,
        lastActiveAt: null,
      },
      system: {
        banReason: null,
        suspendUntil: null,
        notes: 'System SuperAdmin - Full Access',
      },
    });

    return { success: true, message: 'SuperAdmin created successfully' };
  });
```

Then deploy and call this function once from your app.

### Option B: Flutter Script (Quick & Dirty)

Add a temporary button in your login screen that calls:

```dart
Future<void> _seedSuperAdmin() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  await FirebaseFirestore.instance.collection('users').doc(uid).set({
    'uid': uid,
    'role': 'superAdmin',
    // ... rest of the fields
  });

  AppHelpers.showSuccess(message: 'SuperAdmin document created!');
}
```

---

## 📞 Need Help?

If you're still experiencing issues after following this guide:

1. Check Firebase Console → Firestore to verify all documents exist
2. Check Firebase Console → Functions to verify all functions are deployed
3. Check Flutter logs for specific error messages
4. Verify your Firebase project ID in `firebase_options.dart` matches your console

---

## ✅ Final Checklist

- [ ] Created `users/{uid}` document with role="superAdmin"
- [ ] Created `configurations/app_settings` document
- [ ] Created 8 permission documents in `permissions` collection
- [ ] Deployed Cloud Functions
- [ ] Tested sign-in → dashboard loads
- [ ] Tested sign-out → no errors
- [ ] Tested re-login → works perfectly

Once all items are checked, your SuperAdmin setup is complete! 🎉
