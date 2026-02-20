# 💳 SHIRAH Payment System — Complete Technical Documentation

> **Document Type:** Technical Reference  
> **Version:** 1.0  
> **Last Updated:** February 20, 2026  
> **Stack:** Firebase Cloud Functions v2 + Flutter + UddoktaPay  
> **Region:** asia-south1 (Mumbai)  

---

## 📑 Table of Contents

1. [System Overview](#1-system-overview)
2. [Firestore Collections](#2-firestore-collections)
3. [Cloud Functions — Complete Reference](#3-cloud-functions--complete-reference)
4. [Verification System](#4-verification-system)
5. [Subscription System](#5-subscription-system)
6. [Commission Distribution Engine](#6-commission-distribution-engine)
7. [Undistributed Commission (App Funding)](#7-undistributed-commission-app-funding)
8. [Admin Operations](#8-admin-operations)
9. [Flutter Integration Layer](#9-flutter-integration-layer)
10. [Error Handling & Edge Cases](#10-error-handling--edge-cases)
11. [Configuration System](#11-configuration-system)
12. [Data Integrity & Audit Trail](#12-data-integrity--audit-trail)

---

## 1. System Overview

### What the Payment System Does

The SHIRAH payment system handles two types of one-time purchases:

| Type | Price | What User Gets | Commission Levels |
|------|-------|-----------------|-------------------|
| **Verification** | ৳250 | Account verified, can post & withdraw | 10 upline levels |
| **Subscription** | ৳400 | Premium features + auto-verification | 15 upline levels |

### Key Business Rules

1. **Both payments are one-time** — no renewal, lifetime access
2. **Subscription includes verification** — subscribing auto-verifies the account
3. **Users can buy in any order** — verification first, or subscription directly
4. **Commission is earned as Reward Points** — 100 points = ৳1 BDT
5. **Only verified uplines receive commission** — unverified uplines' share goes to app funding
6. **Conversion rate:** 100 Reward Points = ৳1 BDT

### Money Flow

```
User pays ৳250 (Verification)
├── ৳125 (50%) → Distributed as Reward Points to 10 upline levels
│   ├── Verified uplines → Receive reward points
│   └── Missing/Unverified uplines → app_funding_transactions
└── ৳125 (50%) → SHIRAH platform revenue

User pays ৳400 (Subscription)
├── ৳240 (60%) → Distributed as Reward Points to 15 upline levels
│   ├── Verified uplines → Receive reward points
│   └── Missing/Unverified uplines → app_funding_transactions
└── ৳160 (40%) → SHIRAH platform revenue
```

---

## 2. Firestore Collections

### 2.1 `payment_transactions`

Stores every payment transaction created through UddoktaPay.

```
payment_transactions/{transactionId}
├── id : String                          # Document ID (auto-generated)
├── uid : String                         # User who made the payment
├── type : String                        # "verification" | "subscription"
├── amount : Number                      # Payment amount in BDT
├── status : String                      # "completed" | "pending" | "failed" | "canceled"
├── paymentMethod : String               # "bkash" | "nagad" | "rocket" | "upay" | "bank"
├── invoiceId : String                   # UddoktaPay invoice ID (unique, prevents replay)
├── transactionId : String               # UddoktaPay transaction ID
├── senderNumber : String                # Payer's mobile number
├── fee : String                         # Gateway fee amount
├── chargedAmount : String               # Total charged to user
├── metadata : Map                       # Additional UddoktaPay response data
│   ├── fullName : String
│   ├── email : String
│   └── date : String
├── processedAt : Timestamp?             # When verification/subscription was applied
├── processedBy : String?                # "system" | admin UID
├── createdAt : Timestamp                # Transaction creation time
└── updatedAt : Timestamp                # Last update time
```

**Example Document:**
```json
{
  "id": "PTX_a1b2c3d4",
  "uid": "USR_john_doe_uid",
  "type": "verification",
  "amount": 250,
  "status": "completed",
  "paymentMethod": "bkash",
  "invoiceId": "INV-20260220-ABC123",
  "transactionId": "TXN-BKASH-XYZ789",
  "senderNumber": "01712345678",
  "fee": "0.00",
  "chargedAmount": "250.00",
  "metadata": {
    "fullName": "John Doe",
    "email": "john@email.com",
    "date": "2026-02-20"
  },
  "processedAt": "Timestamp(2026-02-20T10:00:05Z)",
  "processedBy": "system",
  "createdAt": "Timestamp(2026-02-20T10:00:00Z)",
  "updatedAt": "Timestamp(2026-02-20T10:00:05Z)"
}
```

---

### 2.2 `reward_transactions`

Stores commission points awarded to each upline.

```
reward_transactions/{rewardId}
├── id : String                          # Document ID
├── uid : String                         # Upline who receives reward
├── sourceUid : String                   # User who made the payment
├── type : String                        # "verification_reward" | "subscription_reward"
├── points : Number                      # Reward points credited
├── level : Number                       # Upline level (1-10 or 1-15)
├── reason : String                      # Human-readable reason
└── createdAt : Timestamp
```

**Example:**
```json
{
  "id": "RWD_xyz123",
  "uid": "USR_upline_1_uid",
  "sourceUid": "USR_john_doe_uid",
  "type": "verification_reward",
  "points": 3125,
  "level": 1,
  "reason": "Verification reward from level 1 downline",
  "createdAt": "Timestamp(2026-02-20T10:00:05Z)"
}
```

---

### 2.3 `app_funding_transactions`

Stores commission that COULD NOT be distributed (missing or unverified upline).

```
app_funding_transactions/{docId}
├── id : String                          # Document ID
├── type : String                        # "verification_undistributed" | "subscription_undistributed"
├── sourceUid : String                   # User who made the payment
├── sourceEvent : String                 # "verification" | "subscription"
├── skippedLevel : Number                # Which level had no eligible upline
├── skippedUplineUid : String | null     # Upline UID (null if no upline at this level)
├── reason : String                      # "no_upline" | "upline_not_verified"
├── points : Number                      # Reward points that were not distributed
├── amountBDT : Number                   # BDT equivalent (points / 100)
└── createdAt : Timestamp
```

**Example (Missing upline):**
```json
{
  "id": "AFT_abc456",
  "type": "verification_undistributed",
  "sourceUid": "USR_john_doe_uid",
  "sourceEvent": "verification",
  "skippedLevel": 7,
  "skippedUplineUid": null,
  "reason": "no_upline",
  "points": 750,
  "amountBDT": 7.50,
  "createdAt": "Timestamp(2026-02-20T10:00:05Z)"
}
```

**Example (Unverified upline):**
```json
{
  "id": "AFT_def789",
  "type": "subscription_undistributed",
  "sourceUid": "USR_john_doe_uid",
  "sourceEvent": "subscription",
  "skippedLevel": 3,
  "skippedUplineUid": "USR_unverified_uncle",
  "reason": "upline_not_verified",
  "points": 2400,
  "amountBDT": 24.00,
  "createdAt": "Timestamp(2026-02-20T10:00:05Z)"
}
```

---

### 2.4 `audit_logs`

Stores immutable audit trail for important actions.

```
audit_logs/{logId}
├── id : String
├── action : String                      # "user.verify" | "user.subscribe" | "payment.approve"
├── performedBy : String                 # "system" | admin UID
├── targetUid : String                   # User affected
├── metadata : Map                       # Additional context
│   ├── paymentTransactionId : String
│   ├── amount : Number
│   └── type : String
└── createdAt : Timestamp
```

---

### 2.5 `configurations/app_settings` — Payment Config Section

```
configurations/app_settings
├── uddoktaPay : Map
│   ├── isSandbox : Boolean              # true = sandbox, false = production
│   ├── sandbox : Map
│   │   ├── apiKey : String
│   │   ├── panelURL : String
│   │   └── redirectURL : String
│   └── production : Map
│       ├── apiKey : String
│       ├── panelURL : String
│       └── redirectURL : String
├── verification : Map
│   ├── priceBDT : Number                # 250
│   ├── rewardDistributedBDT : Number    # 125
│   ├── totalRewardPoints : Number       # 12500
│   └── levelDistribution : Array<Map>   # 10 entries
└── subscription : Map
    ├── priceBDT : Number                # 400
    ├── rewardDistributedBDT : Number    # 240
    ├── totalRewardPoints : Number       # 24000
    └── levelDistribution : Array<Map>   # 15 entries
```

---

## 3. Cloud Functions — Complete Reference

### Function Index

| # | Function | Type | Auth | Admin | File |
|---|----------|------|------|-------|------|
| 1 | `createPaymentTransaction` | `onCall` | ✅ | ❌ | `payment-operations.ts` |
| 2 | `adminApprovePayment` | `onCall` | ✅ | ✅ | `payment-operations.ts` |
| 3 | `getPaymentHistory` | `onCall` | ✅ | ❌ | `payment-operations.ts` |
| 4 | `getAdminPaymentTransactions` | `onCall` | ✅ | ✅ | `payment-operations.ts` |
| 5 | `getPaymentConfig` | `onCall` | ✅ | ❌ | `payment-operations.ts` |
| 6 | `verifyUserProfile` | `onCall` | ✅ | ✅ | `auth-and-verification.ts` |
| 7 | `subscribeUser` | `onCall` | ✅ | ✅ | `auth-and-verification.ts` |
| 8 | `distributeVerificationRewards` | Internal | — | — | `network-graph-operations.ts` |
| 9 | `distributeSubscriptionRewards` | Internal | — | — | `network-graph-operations.ts` |

---

### 3.1 `createPaymentTransaction`

**File:** `functions/src/features/payment/payment-operations.ts`  
**Type:** `functions.https.onCall` (v2)  
**Region:** `asia-south1`  
**Auth Required:** Yes (any authenticated user)

**Purpose:** Called by Flutter after UddoktaPay SDK returns a payment result. Creates a payment record and auto-processes verification or subscription if payment is completed.

**Request Schema:**
```typescript
{
  type: "verification" | "subscription",
  uddoktapayResponse: {
    fullName: string,
    email: string,
    amount: string,
    fee: string,
    chargedAmount: string,
    invoiceId: string,        // Unique, prevents replay
    paymentMethod: string,    // bkash, nagad, rocket, etc.
    senderNumber: string,
    transactionId: string,
    date: string,
    status: "COMPLETED" | "PENDING" | "ERROR"
  }
}
```

**Success Response (Verification):**
```json
{
  "success": true,
  "message": "Payment successful. Profile verified!",
  "data": {
    "paymentTransactionId": "PTX_abc123",
    "verified": true,
    "subscribed": false
  }
}
```

**Success Response (Subscription):**
```json
{
  "success": true,
  "message": "Payment successful. Subscription activated!",
  "data": {
    "paymentTransactionId": "PTX_def456",
    "verified": true,
    "subscribed": true
  }
}
```

**Error Responses:**
```json
// User already verified
{
  "success": false,
  "message": "User is already verified."
}

// Duplicate invoiceId
{
  "success": false,
  "message": "Duplicate payment transaction."
}

// Account not active
{
  "success": false,
  "message": "Account is not in active state."
}
```

**Internal Logic (Step-by-Step):**
```
1. Extract auth context → get user UID
2. Validate: user exists, account active
3. Validate: type is "verification" or "subscription"
4. Validate: user doesn't already have the status
5. Check invoiceId uniqueness across payment_transactions
6. Map UddoktaPay status: "COMPLETED"→"completed", "PENDING"→"pending", "ERROR"→"failed"
7. Create payment_transactions document
8. If status == "completed":
   a. For "verification": call processVerification(uid, tx)
   b. For "subscription": call processSubscription(uid, tx)
9. Return result with updated user status
```

**Use Cases:**
- After user completes bKash payment via UddoktaPay WebView
- After user completes Nagad/Rocket/bank payment
- When payment is pending (bKash timeout) — saves as pending for admin approval

**Flutter Call:**
```dart
final result = await PaymentRepository.instance.createPaymentTransaction(
  type: 'verification',
  uddoktapayResponse: responseFromSdk.toMap(),
);
```

---

### 3.2 `adminApprovePayment`

**File:** `functions/src/features/payment/payment-operations.ts`  
**Type:** `functions.https.onCall` (v2)  
**Region:** `asia-south1`  
**Auth Required:** Yes (admin role)  
**Permission Required:** `payment.approve`

**Purpose:** Allows an admin to manually approve a pending payment and trigger verification/subscription processing.

**Request Schema:**
```typescript
{
  paymentTransactionId: string
}
```

**Success Response:**
```json
{
  "success": true,
  "message": "Payment approved. User verified successfully."
}
```

**Error Responses:**
```json
// Not admin
{ "success": false, "message": "Unauthorized. Admin access required." }

// Transaction not found
{ "success": false, "message": "Payment transaction not found." }

// Already processed
{ "success": false, "message": "Payment is already completed." }
```

**Internal Logic:**
```
1. Verify caller is admin with payment.approve permission
2. Load payment_transactions document
3. Verify status is "pending" (not already completed)
4. Update status to "completed", set processedBy to admin UID
5. Call processVerification() or processSubscription() based on type
6. Write audit_log entry
7. Return success
```

**Use Cases:**
- User contacts support saying "I paid via bKash but account not verified"
- Admin verifies payment in UddoktaPay dashboard, then approves in SHIRAH
- Pending payments that never received callback from UddoktaPay

---

### 3.3 `getPaymentHistory`

**File:** `functions/src/features/payment/payment-operations.ts`  
**Type:** `functions.https.onCall` (v2)  
**Region:** `asia-south1`  
**Auth Required:** Yes

**Purpose:** Returns the authenticated user's payment transaction history, paginated.

**Request Schema:**
```typescript
{
  limit?: number,       // default: 20, max: 50
  startAfter?: string   // last document ID for pagination
}
```

**Response:**
```json
{
  "success": true,
  "message": "Payment history retrieved",
  "data": [
    {
      "id": "PTX_abc123",
      "type": "verification",
      "amount": 250,
      "status": "completed",
      "paymentMethod": "bkash",
      "invoiceId": "INV-xxx",
      "transactionId": "TXN-xxx",
      "createdAt": "2026-02-20T10:00:00Z"
    }
  ]
}
```

**Internal Logic:**
```
1. Get auth UID
2. Query payment_transactions where uid == auth.uid
3. Order by createdAt descending
4. Apply limit and pagination cursor
5. Return sanitized transaction list
```

**Use Cases:**
- User views their payment history in the Verification screen
- Support reference when user asks about a past payment
- Flutter displays this in `PaymentHistoryList` widget

---

### 3.4 `getAdminPaymentTransactions`

**File:** `functions/src/features/payment/payment-operations.ts`  
**Type:** `functions.https.onCall` (v2)  
**Region:** `asia-south1`  
**Auth Required:** Yes (admin role)  
**Permission Required:** `payment.approve`

**Purpose:** Returns payment transactions for admin review, with filtering by status and type.

**Request Schema:**
```typescript
{
  limit?: number,         // default: 50
  status?: string,        // "pending" | "completed" | "failed"
  type?: string,          // "verification" | "subscription"
  startAfter?: string
}
```

**Response:**
```json
{
  "success": true,
  "message": "Admin payment transactions retrieved",
  "data": [
    {
      "id": "PTX_abc123",
      "uid": "USR_john",
      "type": "verification",
      "amount": 250,
      "status": "pending",
      "paymentMethod": "bkash",
      "senderNumber": "01712345678",
      "invoiceId": "INV-xxx",
      "createdAt": "2026-02-20T10:00:00Z"
    }
  ]
}
```

**Use Cases:**
- Admin dashboard showing all pending payments for approval
- Admin filtering by type to see only subscription payments
- Admin reviewing failed payments for investigation

---

### 3.5 `getPaymentConfig`

**File:** `functions/src/features/payment/payment-operations.ts`  
**Type:** `functions.https.onCall` (v2)  
**Region:** `asia-south1`  
**Auth Required:** Yes

**Purpose:** Returns the active UddoktaPay configuration (keys, URLs, prices) to the Flutter app. The app uses this to initialize the UddoktaPay SDK.

**Request:** None (just authenticated call)

**Response:**
```json
{
  "success": true,
  "message": "Payment configuration retrieved",
  "data": {
    "isSandbox": true,
    "apiKey": "KEY-xxxxxxxx...",
    "panelURL": "https://sandbox.uddoktapay.com",
    "redirectURL": "https://sandbox.uddoktapay.com",
    "verificationPriceBDT": 250,
    "subscriptionPriceBDT": 400
  }
}
```

**Internal Logic:**
```
1. Load app config (30s cache)
2. Read uddoktaPay.isSandbox flag
3. Select sandbox or production environment keys
4. Return active keys + prices
```

**Security Note:**  
This function returns the API key to the client. This is intentional — UddoktaPay requires the API key to be passed to the client SDK. The API key alone cannot be used to create fraudulent payments because:
- Payment processing is verified server-side via `createPaymentTransaction`
- The API key can only initiate payment requests, not confirm them
- UddoktaPay validates the merchant account on their end

---

### 3.6 `processVerification` (Internal Function)

**File:** `functions/src/features/auth/auth-and-verification.ts`  
**Exported:** No (internal helper, called by `createPaymentTransaction` and `adminApprovePayment`)

**Purpose:** Processes account verification after successful payment.

**Logic (Step-by-Step):**
```
1. Get user document
2. Check if already verified → skip if yes
3. Set user status: verified = true, verifiedAt = now
4. Get user's upline chain (up to 10 levels)
5. Call distributeVerificationRewards(uid, uplineChain, config)
   → Each verified upline receives reward points
   → Each missing/unverified upline → app_funding_transactions entry
6. Write audit_log: action = "user.verify"
7. Update payment_transactions: processedAt = now
```

---

### 3.7 `processSubscription` (Internal Function)

**File:** `functions/src/features/auth/auth-and-verification.ts`  
**Exported:** No (internal helper)

**Purpose:** Processes subscription activation + auto-verification after successful payment.

**Logic (Step-by-Step):**
```
1. Get user document
2. Check if already subscribed → skip if yes
3. Set user status:
   - subscription = "active"
   - subscribedAt = now
   - verified = true          ← Auto-verify on subscription!
   - verifiedAt = now (if not already verified)
4. Get user's upline chain (up to 15 levels)
5. Call distributeSubscriptionRewards(uid, uplineChain, config)
   → Each verified upline receives reward points
   → Each missing/unverified upline → app_funding_transactions entry
6. Write audit_log: action = "user.subscribe"
7. Update payment_transactions: processedAt = now
```

---

### 3.8 `distributeVerificationRewards` (Internal Function)

**File:** `functions/src/features/network/network-graph-operations.ts`  
**Exported:** Yes (used by auth-and-verification.ts)

**Purpose:** Distributes verification reward points to up to 10 upline levels.

**Parameters:**
```typescript
distributeVerificationRewards(
  sourceUid: string,         // User who paid
  uplineChain: string[],     // Array of upline UIDs [level1, level2, ..., level10]
  config: AppConfig,         // App configuration with distribution percentages
  batch: WriteBatch          // Firestore batch for atomic writes
)
```

**Logic:**
```
For each level 1 to 10:
  1. Get upline UID at this level from uplineChain
  2. If no upline at this level:
     → Add to undistributedEntries (reason: "no_upline")
  3. If upline exists but NOT verified:
     → Add to undistributedEntries (reason: "upline_not_verified")
  4. If upline exists AND verified:
     → Calculate points: totalRewardPoints × levelPercent / 100
     → Create reward_transactions document
     → Increment upline's wallet.rewardPoints by points
5. If any undistributedEntries:
   → Call writeUndistributedEntries() to log to app_funding_transactions
```

---

### 3.9 `distributeSubscriptionRewards` (Internal Function)

**File:** `functions/src/features/network/network-graph-operations.ts`  
**Exported:** Yes

**Purpose:** Same as verification rewards but for 15 levels and subscription amounts.

---

### 3.10 `verifyUserProfile` (Admin Manual Verify)

**File:** `functions/src/features/auth/auth-and-verification.ts`  
**Type:** `functions.https.onCall` (v2)  
**Auth Required:** Yes (admin role)

**Purpose:** Admin can manually verify a user without payment (e.g., for test users, VIPs, or support cases).

**Request:**
```json
{ "targetUid": "USR_target_user_uid" }
```

**Note:** This does NOT distribute commission — it's a manual override.

---

### 3.11 `subscribeUser` (Admin Manual Subscribe)

**File:** `functions/src/features/auth/auth-and-verification.ts`  
**Type:** `functions.https.onCall` (v2)  
**Auth Required:** Yes (admin role)

**Purpose:** Admin can manually subscribe a user without payment.

**Request:**
```json
{ "targetUid": "USR_target_user_uid" }
```

**Note:** Also auto-verifies the user. Does NOT distribute commission.

---

## 4. Verification System

### What Changes on Verification

| Field | Before | After |
|-------|--------|-------|
| `users/{uid}.status.verified` | `false` | `true` |
| `users/{uid}.status.verifiedAt` | `null` | `Timestamp` |
| Posting permission | ❌ | ✅ |
| Withdrawal permission | ❌ | ✅ |
| Marketplace access | Limited | Full |

### Verification Commission Distribution

| Level | Upline Gets | Points | BDT |
|-------|-------------|--------|-----|
| 1 (Direct referrer) | 25% | 3,125 | ৳31.25 |
| 2 | 15% | 1,875 | ৳18.75 |
| 3 | 12% | 1,500 | ৳15.00 |
| 4 | 10% | 1,250 | ৳12.50 |
| 5 | 8% | 1,000 | ৳10.00 |
| 6 | 7% | 875 | ৳8.75 |
| 7 | 6% | 750 | ৳7.50 |
| 8 | 6% | 750 | ৳7.50 |
| 9 | 6% | 750 | ৳7.50 |
| 10 | 5% | 625 | ৳6.25 |
| **Total** | **100%** | **12,500** | **৳125** |

---

## 5. Subscription System

### What Changes on Subscription

| Field | Before | After |
|-------|--------|-------|
| `users/{uid}.status.subscription` | `"none"` | `"active"` |
| `users/{uid}.status.subscribedAt` | `null` | `Timestamp` |
| `users/{uid}.status.verified` | `false` or `true` | **`true`** ← Auto |
| Premium features | ❌ | ✅ |
| Priority support | ❌ | ✅ |
| Advanced analytics | ❌ | ✅ |

### Subscription Commission Distribution

| Level | Upline Gets | Points | BDT |
|-------|-------------|--------|-----|
| 1 | 25% | 6,000 | ৳60.00 |
| 2 | 15% | 3,600 | ৳36.00 |
| 3 | 10% | 2,400 | ৳24.00 |
| 4 | 8% | 1,920 | ৳19.20 |
| 5 | 7% | 1,680 | ৳16.80 |
| 6 | 6% | 1,440 | ৳14.40 |
| 7 | 5% | 1,200 | ৳12.00 |
| 8 | 4% | 960 | ৳9.60 |
| 9 | 4% | 960 | ৳9.60 |
| 10 | 3% | 720 | ৳7.20 |
| 11 | 3% | 720 | ৳7.20 |
| 12 | 2% | 480 | ৳4.80 |
| 13 | 2% | 480 | ৳4.80 |
| 14 | 1.5% | 360 | ৳3.60 |
| 15 | 1.5% | 360 | ৳3.60 |
| **Total** | **97%** | **24,000** | **৳240** |

> **Note:** The 97% total for subscription is by design. The sum of defined percentages = 97%. The remaining 3% goes to SHIRAH platform on top of the 40% platform cut. Total platform share = ৳160 + ৳7.20 = ৳167.20 per subscription.

---

## 6. Commission Distribution Engine

### How It Works

```
User A pays ৳250 for verification
    │
    ├── User A's upline chain:
    │   Level 1: User B (verified ✅) → Gets 3,125 points
    │   Level 2: User C (not verified ❌) → app_funding_transactions
    │   Level 3: User D (verified ✅) → Gets 1,500 points
    │   Level 4: (no upline) → app_funding_transactions
    │   Level 5-10: ... (same logic)
    │
    └── Result:
        ├── User B: +3,125 reward points
        ├── User D: +1,500 reward points
        ├── app_funding: 2 entries (User C skip + Level 4 no upline)
        └── All writes in single Firestore batch (atomic)
```

### Upline Chain Resolution

The system reads the `network/uplineChain` sub-collection or `network.parentUid` chain:

```
User A → parentUid: User B
User B → parentUid: User C
User C → parentUid: User D
User D → parentUid: null (root)
```

This gives: [User B, User C, User D, null, null, ...] for 10 or 15 levels.

### Atomicity

All commission distribution happens in a **single Firestore batch write**:
- All reward_transactions created
- All wallet.rewardPoints incremented
- All app_funding_transactions created
- User status updated

If any part fails, the entire batch rolls back. No partial distributions.

---

## 7. Undistributed Commission (App Funding)

### When Commission Goes to App Funding

| Scenario | Reason Code | Example |
|----------|-------------|---------|
| No upline at level N | `no_upline` | User was invited by root user, Level 3+ has no one |
| Upline exists but not verified | `upline_not_verified` | Level 2 upline registered but hasn't paid ৳250 |

### What Happens to Undistributed Points

Currently, undistributed points are **logged for accounting** in `app_funding_transactions`. They are:
- Visible to SuperAdmin in admin dashboard
- Available for future features (e.g., platform rewards pool, charity fund)
- Used for financial auditing (total paid vs total distributed + undistributed = 100%)

### Querying Undistributed Totals (Admin)

```typescript
// Get total undistributed from verification
const verificationTotal = await db.collection('app_funding_transactions')
  .where('type', '==', 'verification_undistributed')
  .get();

const totalPoints = verificationTotal.docs.reduce(
  (sum, doc) => sum + doc.data().points, 0
);
const totalBDT = totalPoints / 100;
```

---

## 8. Admin Operations

### Available Admin Actions

| Action | Function | Permission |
|--------|----------|------------|
| Approve pending payment | `adminApprovePayment` | `payment.approve` |
| View all payment transactions | `getAdminPaymentTransactions` | `payment.approve` |
| Manually verify user (no payment, no commission) | `verifyUserProfile` | Admin role |
| Manually subscribe user (no payment, no commission) | `subscribeUser` | Admin role |

### Admin Approval Workflow

```
1. User pays via bKash → UddoktaPay returns "PENDING"
2. Flutter calls createPaymentTransaction with status "pending"
3. Admin opens admin panel → sees pending payment
4. Admin verifies in UddoktaPay dashboard that payment was received
5. Admin clicks "Approve" → adminApprovePayment
6. Cloud Function:
   - Updates payment_transactions status → "completed"
   - Calls processVerification/processSubscription
   - Distributes commission
   - Writes audit log
7. User's account is now verified/subscribed
```

---

## 9. Flutter Integration Layer

### Repository Pattern

```
VerificationController (GetX)
    │
    ├── loadPaymentConfig()          → PaymentRepository.getPaymentConfig()
    ├── purchaseVerification()       → UddoktaPay SDK + PaymentRepository
    ├── purchaseSubscription()       → UddoktaPay SDK + PaymentRepository
    └── loadPaymentHistory()         → PaymentRepository.getPaymentHistory()
                │
                ▼
PaymentRepository
    │
    ├── getPaymentConfig()           → CloudFunctionsService.getPaymentConfig()
    ├── createPaymentTransaction()   → CloudFunctionsService.createPaymentTransaction()
    └── getPaymentHistory()          → CloudFunctionsService.getPaymentHistory()
                │
                ▼
CloudFunctionsService
    │
    └── _callFunction('functionName', data) → FirebaseFunctions.httpsCallable()
```

### Controller Pattern

```dart
class VerificationController extends GetxController {
  static VerificationController get instance => Get.find();

  final _paymentRepo = PaymentRepository.instance;

  // Observable state
  final isVerified = false.obs;
  final isSubscribed = false.obs;
  final isLoading = false.obs;
  final paymentConfig = Rxn<Map<String, dynamic>>();
  final paymentHistory = <PaymentTransactionModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadUserStatus();
    loadPaymentConfig();
  }

  Future<void> purchaseVerification() async {
    // 1. Check already verified
    // 2. Load config if needed
    // 3. Show loading
    // 4. Open UddoktaPay SDK
    // 5. Handle result → createPaymentTransaction
    // 6. Refresh user data
  }

  Future<void> purchaseSubscription() async {
    // Same flow — NO verification check required
    // Backend auto-verifies on subscription
  }
}
```

---

## 10. Error Handling & Edge Cases

### Edge Cases Handled

| Edge Case | How It's Handled |
|-----------|------------------|
| User pays twice for verification | `invoiceId` duplicate check, "already verified" check |
| User pays verification then subscription | Both work independently, subscription auto-verifies (no duplicate) |
| User pays subscription directly | Auto-verifies + subscribes in one go |
| Payment completes but Cloud Function fails | Payment saved as pending, admin can approve manually |
| User has no upline chain | All commission goes to app_funding_transactions |
| Network timeout during payment | UddoktaPay handles retry, SDK returns appropriate status |
| User closes app during payment | Payment may complete on UddoktaPay side → admin can verify and approve |
| Same invoiceId sent twice | Second call rejected with "Duplicate payment" |
| Admin approves already-completed payment | Rejected with "Already completed" |

### Error Response Format

All Cloud Functions return consistent error format:
```json
{
  "success": false,
  "message": "Human-readable error message",
  "error": "ERROR_CODE"
}
```

---

## 11. Configuration System

### Dynamic Config (Firestore-backed, cached)

**File:** `functions/src/config/dynamic-config.ts`

```typescript
// Config is cached in memory with 30-second TTL
// Any change to configurations/app_settings takes effect within 30 seconds
// No redeployment required

const config = await getAppConfig();
// config.uddoktaPay.isSandbox → true/false
// config.verification.priceBDT → 250
// config.subscription.priceBDT → 400
// config.verification.levelDistribution → [{level: 1, percent: 25, points: 3125}, ...]
```

### Static Constants

**File:** `functions/src/config/constants.ts`

```typescript
// These require redeployment to change
export const REGION = "asia-south1";
export const VERIFICATION_DEPTH = 10;        // Max upline levels for verification
export const SUBSCRIPTION_DEPTH = 15;        // Max upline levels for subscription
export const POINTS_TO_BDT_RATE = 100;       // 100 points = 1 BDT
export const INVITE_CODE_LENGTH = 8;         // S + 6 chars + L
```

### How to Change Prices Without Deployment

1. Go to Firebase Console → Firestore → `configurations/app_settings`
2. Change `verification.priceBDT` or `subscription.priceBDT`
3. Change the corresponding `totalRewardPoints` and `levelDistribution`
4. Changes take effect in 30 seconds

---

## 12. Data Integrity & Audit Trail

### Audit Trail Events

| Event | Action Code | When |
|-------|-------------|------|
| User verified via payment | `user.verify` | After processVerification |
| User subscribed via payment | `user.subscribe` | After processSubscription |
| Admin approved payment | `payment.approve` | After adminApprovePayment |
| Admin manually verified | `admin.verify.user` | After verifyUserProfile |
| Admin manually subscribed | `admin.subscribe.user` | After subscribeUser |

### Financial Audit Formula

For every payment, the following must balance:

```
Total Payment = Platform Revenue + Distributed Commission + Undistributed Commission

Verification (৳250):
250 = 125 (platform) + sum(distributed_points/100) + sum(undistributed_points/100)

Subscription (৳400):
400 = 160 (platform) + sum(distributed_points/100) + sum(undistributed_points/100)
```

### Data Consistency Checks

- `payment_transactions` count = number of UddoktaPay transactions
- `reward_transactions` + `app_funding_transactions` points per payment = expected distribution
- `users.wallet.rewardPoints` = sum of all `reward_transactions` for that user
- `audit_logs` has entry for every status change

---

**END OF PAYMENT SYSTEM DOCUMENTATION**
