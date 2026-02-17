# 🚀 How to Create the First User (Super Admin) in SHIRAH

> **Critical Understanding**: This is an **admin panel app**, NOT a public user app. Regular users CANNOT create accounts through this Flutter app. This app is ONLY for admins to manage the SHIRAH system.

---

## 🎯 The Problem: Chicken and Egg

**Question**: If every user needs an invite code to signup, how does the first user get created?

**Answer**: The first user (Super Admin) is created **MANUALLY** using Firebase Console + Cloud Functions, NOT through the Flutter app.

---

## 📋 System Architecture Overview

### User Types in SHIRAH

| User Type | Created How | Can Use Flutter App |
|-----------|-------------|---------------------|
| **Super Admin** | Manual (Firebase + Script) | ✅ YES |
| **Admin** | By Super Admin | ✅ YES |
| **Moderator** | By Super Admin/Admin | ✅ YES |
| **Support** | By Super Admin/Admin | ✅ YES |
| **Regular User** | Through main SHIRAH user app | ❌ NO (different app) |

### Important Distinction

```
┌─────────────────────────────────────┐
│  SHIRAH Admin Panel (This App)  │
│  - For system administrators only   │
│  - Manages users, permissions, etc  │
│  - Requires invite code             │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│  SHIRAH User App (Separate App)  │
│  - For regular users                │
│  - Public signup with invite codes  │
│  - Earns rewards, views ads, etc    │
└─────────────────────────────────────┘
```

---

## 🔧 Step-by-Step: Create Super Admin

### Prerequisites

1. Firebase project set up
2. Cloud Functions deployed
3. Firebase CLI installed
4. Admin access to Firebase Console

---

### Method 1: Using Cloud Functions Script (Recommended)

#### Step 1: Navigate to Functions Directory

```bash
cd functions
```

#### Step 2: Run Super Admin Creation Script

```bash
npm run create-super-admin
```

#### Step 3: Follow the Interactive Prompts

The script will ask for:
- Email address
- Password
- First name
- Last name
- Phone number

#### Step 4: Verify Creation

The script will output:
- ✅ Super Admin UID
- ✅ Super Admin invite code
- ✅ Firestore document created
- ✅ Auth user created

**SAVE THE INVITE CODE!** This is the ONLY invite code that exists in the system initially.

---

### Method 2: Manual Creation (If Script Fails)

#### Step 1: Create Firebase Auth User

1. Go to Firebase Console
2. Authentication → Users → Add User
3. Enter:
   - Email: `contact.labibur@gmail.com`
   - Password: `Shirah@@282220!!`
4. Copy the generated UID

#### Step 2: Create Firestore Document

Go to Firestore → `users` collection → Create document with this structure:

```json
{
  "uid": "PASTE_UID_HERE",
  "role": "superAdmin",
  
  "identity": {
    "firstName": "Super",
    "lastName": "Admin",
    "email": "superadmin@SHIRAH.com",
    "phone": "+8801XXXXXXXXX",
    "authProvider": "password",
    "photoURL": "",
    "coverURL": ""
  },
  
  "codes": {
    "inviteCode": "GENERATE_8_CHAR_CODE",
    "referralCode": "PASTE_UID_HERE"
  },
  
  "network": {
    "parentUid": null,
    "joinedVia": ""
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
    "lastLimitReset": "2026-02-05"
  },
  
  "meta": {
    "createdAt": "SERVER_TIMESTAMP",
    "updatedAt": "SERVER_TIMESTAMP",
    "lastLoginAt": null,
    "lastActiveAt": null
  },
  
  "system": {
    "banReason": null,
    "suspendUntil": null,
    "notes": "Manually created super admin"
  }
}
```

#### Step 3: Create Invite Code Document

Go to Firestore → `invite_codes` collection → Create document:

Document ID: `YOUR_8_CHAR_CODE` (e.g., "SA7K9Q2L")

```json
{
  "uid": "SUPER_ADMIN_UID",
  "email": "superadmin@SHIRAH.com",
  "createdAt": "SERVER_TIMESTAMP"
}
```

#### Step 4: Create User Uplines Document

Go to Firestore → `user_uplines` collection → Create document:

Document ID: `SUPER_ADMIN_UID`

```json
{
  "u1": null,
  "u2": null,
  "u3": null,
  "u4": null,
  "u5": null,
  "u6": null,
  "u7": null,
  "u8": null,
  "u9": null,
  "u10": null,
  "u11": null,
  "u12": null,
  "u13": null,
  "u14": null,
  "u15": null,
  "maxDepth": 15,
  "createdAt": "SERVER_TIMESTAMP"
}
```

#### Step 5: Create Network Stats Document

Go to Firestore → `user_network_stats` collection → Create document:

Document ID: `SUPER_ADMIN_UID`

```json
{
  "level1": { "total": 0, "verified": 0, "subscribed": 0 },
  "level2": { "total": 0, "verified": 0, "subscribed": 0 },
  "level3": { "total": 0, "verified": 0, "subscribed": 0 },
  "level4": { "total": 0, "verified": 0, "subscribed": 0 },
  "level5": { "total": 0, "verified": 0, "subscribed": 0 },
  "level6": { "total": 0, "verified": 0, "subscribed": 0 },
  "level7": { "total": 0, "verified": 0, "subscribed": 0 },
  "level8": { "total": 0, "verified": 0, "subscribed": 0 },
  "level9": { "total": 0, "verified": 0, "subscribed": 0 },
  "level10": { "total": 0, "verified": 0, "subscribed": 0 },
  "level11": { "total": 0, "verified": 0, "subscribed": 0 },
  "level12": { "total": 0, "verified": 0, "subscribed": 0 },
  "level13": { "total": 0, "verified": 0, "subscribed": 0 },
  "level14": { "total": 0, "verified": 0, "subscribed": 0 },
  "level15": { "total": 0, "verified": 0, "subscribed": 0 },
  "updatedAt": "SERVER_TIMESTAMP"
}
```

---

## 🎯 After Super Admin is Created

### Step 1: Login to Flutter Admin App

1. Open the SHIRAH Admin Panel app
2. Use the Super Admin credentials:
   - Email: `superadmin@SHIRAH.com`
   - Password: `SecurePassword123!`

### Step 2: Create Additional Admins

Now that you have a Super Admin account, you can:

1. **Share the invite code** with trusted team members
2. They can signup using the invite code
3. Once they signup, you can **promote them to admin** through:
   - Firebase Console (manually change role)
   - Admin panel (if you build role management UI)

---

## 🔒 Security Best Practices

### Super Admin Account

✅ **DO:**
- Use strong, unique password (20+ characters)
- Enable 2FA in Firebase Console
- Limit to 1-3 accounts maximum
- Store credentials in secure password manager
- Never share Super Admin credentials

❌ **DON'T:**
- Use Super Admin for daily operations
- Share Super Admin invite code publicly
- Use simple passwords
- Store credentials in code or documents

### Invite Code Management

✅ **DO:**
- Keep Super Admin invite code private
- Share only with verified team members
- Track who used which invite code
- Revoke/delete unused accounts

❌ **DON'T:**
- Post invite codes publicly
- Share in unsecured channels
- Reuse for untrusted users

---

## 🐛 Troubleshooting

### Problem: "Invite code not found" during signup

**Solution**: Make sure you created the `invite_codes/{code}` document in Firestore.

### Problem: "Parent account not active"

**Solution**: Verify the Super Admin account has `status.accountState = "active"` in Firestore.

### Problem: Can't login after creation

**Solution**: 
1. Check Firebase Authentication → Users → Verify user exists
2. Check Firestore → users → Verify document exists
3. Verify email/password are correct

### Problem: Cloud Functions returning errors

**Solution**:
1. Check Firebase Console → Functions → Logs
2. Verify all required collections exist
3. Ensure Cloud Functions are deployed: `firebase deploy --only functions`

---

## 📊 Verification Checklist

After creating Super Admin, verify these documents exist:

- [ ] Firebase Authentication user exists
- [ ] `users/{uid}` document exists with `role: "superAdmin"`
- [ ] `invite_codes/{code}` document exists
- [ ] `user_uplines/{uid}` document exists (all levels null)
- [ ] `user_network_stats/{uid}` document exists (all zeros)
- [ ] Super Admin can login to Flutter app
- [ ] Super Admin invite code is saved securely

---

## 🎓 Understanding the Flow

```
┌──────────────────────────────────────────────────────────────┐
│ STEP 1: Manual Super Admin Creation                         │
│ ├─ Firebase Auth: Create user                               │
│ ├─ Firestore: Create user document (role: superAdmin)       │
│ ├─ Firestore: Create invite_codes document                  │
│ ├─ Firestore: Create user_uplines (all null)                │
│ └─ Firestore: Create user_network_stats (all zeros)         │
└──────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────┐
│ STEP 2: Super Admin Shares Invite Code                      │
│ └─ Team member receives: "SA7K9Q2L"                         │
└──────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────┐
│ STEP 3: Team Member Signup (Through Flutter App)            │
│ ├─ Enters invite code: "SA7K9Q2L"                           │
│ ├─ Cloud Function validates code                            │
│ ├─ Cloud Function creates user                              │
│ ├─ Network graph built (parent = Super Admin)               │
│ └─ User can login                                            │
└──────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────┐
│ STEP 4: Super Admin Promotes to Admin Role                  │
│ ├─ Firebase Console: Change role to "admin"                 │
│ ├─ Create admin_permissions document                        │
│ └─ Admin can now manage system                              │
└──────────────────────────────────────────────────────────────┘
```

---

## 🔑 Key Takeaways

1. **Super Admin is created manually** - NOT through Flutter signup
2. **Flutter signup requires invite code** - No exceptions
3. **Super Admin invite code is the first code** - Guard it carefully
4. **This is an admin-only app** - Not for regular users
5. **Regular users use different app** - SHIRAH User App (separate)

---

## 📞 Support

If you encounter issues:

1. Check Firebase Console → Firestore → Verify documents
2. Check Firebase Console → Functions → Logs
3. Check Flutter app logs
4. Review documentation: `documents/` folder
5. Contact system architect

---

**Last Updated**: February 5, 2026  
**Version**: 1.0  
**Author**: SHIRAH Technical Team
