# 🔐 UddoktaPay Payment Gateway — Complete Setup & Integration Guide

> **Document Type:** Setup & Integration Reference  
> **Version:** 1.0  
> **Last Updated:** February 20, 2026  
> **Audience:** Developers, DevOps, Project Owners  
> **Stack:** Flutter (uddoktapay package) + Firebase Cloud Functions  

---

## 📑 Table of Contents

1. [Overview](#1-overview)
2. [Architecture & Security Model](#2-architecture--security-model)
3. [Firestore Configuration — Manual Setup](#3-firestore-configuration--manual-setup)
4. [UddoktaPay Dashboard Setup](#4-uddoktapay-dashboard-setup)
5. [Flutter Integration](#5-flutter-integration)
6. [Cloud Functions Reference](#6-cloud-functions-reference)
7. [Payment Flows (Step-by-Step)](#7-payment-flows-step-by-step)
8. [Sandbox ↔ Production Switch](#8-sandbox--production-switch)
9. [Commission Distribution Logic](#9-commission-distribution-logic)
10. [Google Play Compliance](#10-google-play-compliance)
11. [Troubleshooting](#11-troubleshooting)
12. [Security Checklist](#12-security-checklist)

---

## 1. Overview

SHIRAH uses **UddoktaPay** as the primary payment gateway for collecting payments from Bangladeshi users. It supports bKash, Nagad, Rocket, Upay, and bank transfers.

### What UddoktaPay Handles
- Account Verification fee (one-time ৳250)
- Pro Subscription fee (one-time ৳400)

### Payment Rules
| Rule | Detail |
|------|--------|
| Verification | One-time payment, ৳250, account gets verified |
| Subscription | One-time payment, ৳400, gets BOTH verification + subscription |
| Can buy separately | User can buy verification alone first, then subscription later |
| Can buy subscription directly | Subscription auto-verifies the account |
| No renewal | Both are lifetime, no recurring charges |

---

## 2. Architecture & Security Model

```
┌─────────────────────────────────────────────────────────────────┐
│                     FLUTTER APP                                  │
│                                                                  │
│  1. User taps "Buy"                                              │
│  2. App calls getPaymentConfig() Cloud Function                  │
│  3. App receives API key + prices                                │
│  4. App initializes UddoktaPay SDK                               │
│  5. User completes payment in UddoktaPay WebView                 │
│  6. SDK returns payment result to app                            │
│  7. App sends result to createPaymentTransaction() CF            │
│                                                                  │
└───────────────────────┬─────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│                  CLOUD FUNCTIONS                                 │
│                                                                  │
│  createPaymentTransaction:                                       │
│  1. Validates user auth + account state                          │
│  2. Checks for duplicate invoiceId (prevents replay)             │
│  3. Creates payment_transactions document                        │
│  4. If status == "completed":                                    │
│     → processVerification() or processSubscription()             │
│     → Distributes commission to uplines                          │
│     → Logs undistributed to app_funding_transactions             │
│  5. Returns result to Flutter                                    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Security Principles
- **API key is stored in Firestore `configurations/app_settings`**, not in Flutter code
- Flutter **never** hardcodes API keys or URLs
- All payment processing happens in Cloud Functions (server-side)
- Duplicate invoiceId check prevents payment replay attacks
- User verification status is only changed by Cloud Functions, never by client

---

## 3. Firestore Configuration — Manual Setup

### Collection: `configurations`
### Document ID: `app_settings`

You need to add/update the `uddoktaPay` section inside `configurations/app_settings`.

### Exact Structure to Create

```
configurations (Collection)
└── app_settings (Document)
    └── uddoktaPay (Map)
        ├── isSandbox (Boolean)       → true  (set to false when ready for production)
        ├── sandbox (Map)
        │   ├── apiKey (String)       → "982d381360a69d419689740d9f2e26ce36fb7a50"
        │   ├── panelURL (String)     → "https://sandbox.uddoktapay.com/api/checkout-v2"
        │   └── redirectURL (String)  → ""   ← not used (SDK handles sandbox internally)
        └── production (Map)
            ├── apiKey (String)       → "gimjPurlftSRjjxIRpn2sR4MvooUJQ8snL0mFCVb"
            ├── panelURL (String)     → "https://shirahsoft.paymently.io/api/checkout-v2"
            └── redirectURL (String)  → "shirahsoft.paymently.io"  ← domain only, no https://
```

### Example Data (Copy-Paste into Firestore Console)

```json
{
  "uddoktaPay": {
    "isSandbox": true,
    "sandbox": {
      "apiKey": "982d381360a69d419689740d9f2e26ce36fb7a50",
      "panelURL": "https://sandbox.uddoktapay.com/api/checkout-v2",
      "redirectURL": ""
    },
    "production": {
      "apiKey": "gimjPurlftSRjjxIRpn2sR4MvooUJQ8snL0mFCVb",
      "panelURL": "https://shirahsoft.paymently.io/api/checkout-v2",
      "redirectURL": "shirahsoft.paymently.io"
    }
  }
}
```

> **`panelURL`** = the full checkout-v2 endpoint URL (where UddoktaPay processes the charge)  
> **`redirectURL`** = the **domain only** (no `https://`) that you registered in the UddoktaPay panel. For sandbox, leave it empty — the Flutter SDK handles sandbox internally and does not need credentials.

### Also Ensure These Fields Exist in `app_settings`

```json
{
  "verification": {
    "priceBDT": 250,
    "rewardDistributedBDT": 125,
    "totalRewardPoints": 12500,
    "levelDistribution": [
      { "level": 1, "percent": 25, "points": 3125 },
      { "level": 2, "percent": 15, "points": 1875 },
      { "level": 3, "percent": 12, "points": 1500 },
      { "level": 4, "percent": 10, "points": 1250 },
      { "level": 5, "percent": 8, "points": 1000 },
      { "level": 6, "percent": 7, "points": 875 },
      { "level": 7, "percent": 6, "points": 750 },
      { "level": 8, "percent": 6, "points": 750 },
      { "level": 9, "percent": 6, "points": 750 },
      { "level": 10, "percent": 5, "points": 625 }
    ]
  },
  "subscription": {
    "priceBDT": 400,
    "rewardDistributedBDT": 240,
    "totalRewardPoints": 24000,
    "levelDistribution": [
      { "level": 1, "percent": 25, "points": 6000 },
      { "level": 2, "percent": 15, "points": 3600 },
      { "level": 3, "percent": 10, "points": 2400 },
      { "level": 4, "percent": 8, "points": 1920 },
      { "level": 5, "percent": 7, "points": 1680 },
      { "level": 6, "percent": 6, "points": 1440 },
      { "level": 7, "percent": 5, "points": 1200 },
      { "level": 8, "percent": 4, "points": 960 },
      { "level": 9, "percent": 4, "points": 960 },
      { "level": 10, "percent": 3, "points": 720 },
      { "level": 11, "percent": 3, "points": 720 },
      { "level": 12, "percent": 2, "points": 480 },
      { "level": 13, "percent": 2, "points": 480 },
      { "level": 14, "percent": 1.5, "points": 360 },
      { "level": 15, "percent": 1.5, "points": 360 }
    ]
  },
  "network": {
    "maxDepth": 15,
    "verificationDepth": 10
  }
}
```

### How to Add Manually in Firebase Console

1. Go to **Firebase Console** → **Firestore Database**
2. Navigate to `configurations` collection
3. Click on `app_settings` document (create if not exists)
4. Click **Add field** → Name: `uddoktaPay`, Type: **Map**
5. Inside `uddoktaPay`:
   - Add `isSandbox` → Boolean → `true`
   - Add `sandbox` → Map → add `apiKey`, `panelURL`, `redirectURL` as Strings
   - Add `production` → Map → add `apiKey`, `panelURL`, `redirectURL` as Strings
6. Fill in the actual keys from UddoktaPay dashboard

> ⚠️ **Important:** Changes propagate within **30 seconds** (cache TTL). No redeployment needed.

---

## 4. UddoktaPay Dashboard Setup

### Step 1: Create Account
1. Go to [https://uddoktapay.com](https://uddoktapay.com)
2. Register a merchant account
3. Complete KYC verification (required for production)

### Step 2: Get API Keys

**Sandbox:**
1. Log in to UddoktaPay Dashboard
2. Go to **Settings** → **API Keys**
3. Copy the **Sandbox API Key** (starts with `KEY-`)
4. Sandbox panel URL: `https://sandbox.uddoktapay.com`

**Production:**
1. Complete business verification
2. Go to **Settings** → **API Keys**
3. Copy the **Live API Key** (starts with `KEY-`)
4. Production panel URL: `https://pay.uddoktapay.com`

### Step 3: Configure Webhook (Optional but Recommended)
- Set webhook URL in UddoktaPay dashboard for server-to-server payment confirmation
- Currently SHIRAH uses client-side callback flow (SDK returns result to app)
- For production, consider adding a webhook endpoint in Cloud Functions for extra verification

### Step 4: Store Keys in Firestore
Follow Section 3 above to store keys in `configurations/app_settings`.

---

## 5. Flutter Integration

### 5.1 Package Setup

The `uddoktapay` Flutter package is already added to `pubspec.yaml`.

```yaml
dependencies:
  uddoktapay: ^latest
```

### UddoktaPay SDK — Sandbox vs Production

The `uddoktapay` Flutter package works differently depending on the mode:

| Mode | Credentials required? | How |  
|------|-----------------------|-----|
| **Sandbox** | ❌ No | SDK uses built-in sandbox endpoint automatically — no API key, no panelURL needed |
| **Production** | ✅ Yes | Must pass `UddoktapayCredentials(apiKey, panelURL, redirectURL)` |

**Production credentials for SHIRAH:**
```dart
UddoktapayCredentials(
  apiKey: 'gimjPurlftSRjjxIRpn2sR4MvooUJQ8snL0mFCVb',
  panelURL: 'https://shirahsoft.paymently.io/api/checkout-v2',
  redirectURL: 'shirahsoft.paymently.io',  // domain only, no https://
)
```

The `VerificationController` already handles this automatically based on the `isSandbox` flag returned from `getPaymentConfig` Cloud Function.

### 5.3 Payment Flow in Flutter

```
User taps "Verify Account" or "Subscribe"
    │
    ├── 1. Check if already verified/subscribed → show info if yes
    ├── 2. Ensure payment config is loaded → call loadPaymentConfig() if not
    ├── 3. Show EasyLoading
    ├── 4. Create CustomerDetails from user profile
    ├── 5. Call UddoktaPay.createPayment() → opens payment WebView
    ├── 6. User completes/cancels payment in WebView
    ├── 7. SDK returns RequestResponse with status
    │
    ├── If status == completed:
    │   ├── Call createPaymentTransaction() Cloud Function
    │   ├── Cloud Function auto-processes verification/subscription
    │   ├── Show success snackbar
    │   └── Refresh user data
    │
    ├── If status == pending:
    │   ├── Call createPaymentTransaction() Cloud Function
    │   ├── Transaction saved with "pending" status
    │   └── Show warning: "Payment pending, you'll be notified"
    │
    └── If status == canceled/failed:
        └── Show appropriate error/warning snackbar
```

### 5.4 Key Files in Flutter

| File | Purpose |
|------|---------|
| `lib/features/verification/controllers/verification_controller.dart` | Payment orchestration, UddoktaPay SDK calls |
| `lib/data/repositories/payment_repository.dart` | Cloud Functions API calls wrapper |
| `lib/core/services/cloud_functions_service.dart` | Low-level Cloud Function caller |
| `lib/data/models/payment/payment_transaction_model.dart` | Payment data model |
| `lib/features/verification/views/screens/verification_screen.dart` | UI screen |
| `lib/features/verification/views/widgets/verification_plan_card.dart` | Verification purchase card |
| `lib/features/verification/views/widgets/subscription_plan_card.dart` | Subscription purchase card |
| `lib/features/verification/views/widgets/payment_history_list.dart` | Payment history list |
| `lib/features/verification/views/widgets/verification_status_banner.dart` | Status badge |
| `lib/features/verification/views/widgets/verification_benefits_list.dart` | Benefits display |

---

## 6. Cloud Functions Reference

### 6.1 `getPaymentConfig` — Get Active Payment Configuration

**Type:** `functions.https.onCall`  
**Auth Required:** Yes (any authenticated user)  
**Region:** `asia-south1`

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

**Logic:**
1. Reads `configurations/app_settings` (30s cache)
2. Checks `uddoktaPay.isSandbox`
3. Returns keys from `sandbox` or `production` based on the flag
4. Also returns verification and subscription prices

**Flutter Call:**
```dart
final result = await CloudFunctionsService.instance.getPaymentConfig();
final data = result['data'] as Map<String, dynamic>;
// data['apiKey'], data['panelURL'], data['verificationPriceBDT'], etc.
```

---

### 6.2 `createPaymentTransaction` — Record Payment After UddoktaPay

**Type:** `functions.https.onCall`  
**Auth Required:** Yes  
**Region:** `asia-south1`

**Request:**
```json
{
  "type": "verification",
  "uddoktapayResponse": {
    "fullName": "John Doe",
    "email": "john@email.com",
    "amount": "250.00",
    "fee": "0.00",
    "chargedAmount": "250.00",
    "invoiceId": "INV-xxxxxxxx",
    "paymentMethod": "bkash",
    "senderNumber": "01712345678",
    "transactionId": "TXN-xxxxxxxx",
    "date": "2026-02-20",
    "status": "COMPLETED"
  }
}
```

**Response (Completed):**
```json
{
  "success": true,
  "message": "Payment successful. Profile verified!",
  "data": {
    "paymentTransactionId": "abc123...",
    "verified": true,
    "subscribed": false
  }
}
```

**Logic:**
1. Validates auth, account state, payment type
2. Checks user doesn't already have the status
3. Checks for duplicate `invoiceId` (prevent replay attacks)
4. Maps UddoktaPay status to internal status
5. Creates `payment_transactions` document
6. If completed → calls `processVerification()` or `processSubscription()`
7. Auto-processes: sets user verified/subscribed, distributes commission

**Validations:**
- User must be authenticated
- Account must be in "active" state
- User must not already be verified (for verification type)
- User must not already be subscribed (for subscription type)
- `invoiceId` must be unique (no duplicate payments)

---

### 6.3 `adminApprovePayment` — Admin Manual Approval

**Type:** `functions.https.onCall`  
**Auth Required:** Yes (Admin+ role, or SuperAdmin bypass)  
**Permission Required:** `payment.approve`  
**Region:** `asia-south1`

**Request:**
```json
{
  "paymentTransactionId": "abc123..."
}
```

**Response:**
```json
{
  "success": true,
  "message": "Payment approved. User verified successfully."
}
```

**Use Case:** When a payment is stuck in "pending" state (e.g., bKash timeout), admin can manually approve it after verifying the payment was received.

---

### 6.4 `getPaymentHistory` — User Payment History

**Type:** `functions.https.onCall`  
**Auth Required:** Yes  
**Region:** `asia-south1`

**Request:**
```json
{
  "limit": 20,
  "startAfter": "optional-last-doc-id"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Payment history retrieved",
  "data": [
    {
      "id": "abc123",
      "uid": "user-uid",
      "type": "verification",
      "amount": 250,
      "status": "completed",
      "paymentMethod": "bkash",
      "invoiceId": "INV-xxx",
      "transactionId": "TXN-xxx",
      "senderNumber": "01712345678",
      "fee": "0.00",
      "chargedAmount": "250.00",
      "createdAt": "2026-02-20T10:00:00Z"
    }
  ]
}
```

---

### 6.5 `getAdminPaymentTransactions` — Admin Payment Review

**Type:** `functions.https.onCall`  
**Auth Required:** Yes (Admin+ role)  
**Permission Required:** `payment.approve`  
**Region:** `asia-south1`

**Request:**
```json
{
  "limit": 50,
  "status": "pending",
  "type": "verification"
}
```

**Use Case:** Admin panel to review and manage pending/failed payments.

---

## 7. Payment Flows (Step-by-Step)

### 7.1 Verification Purchase Flow

```
User                  Flutter App              Cloud Functions           Firestore
  │                        │                        │                       │
  ├─ Tap "Verify" ───────►│                        │                       │
  │                        ├── getPaymentConfig() ─►│                       │
  │                        │◄── {apiKey, price...} ─┤                       │
  │                        │                        │                       │
  │                        ├── UddoktaPay SDK       │                       │
  │◄── Payment WebView ───┤   opens browser         │                       │
  │                        │                        │                       │
  ├─ Complete payment ────►│                        │                       │
  │                        │◄── Result from SDK     │                       │
  │                        │                        │                       │
  │                        ├── createPaymentTx() ──►│                       │
  │                        │                        ├── Write payment_tx ──►│
  │                        │                        ├── processVerify() ───►│
  │                        │                        │   ├── user.verified    │
  │                        │                        │   ├── commission       │
  │                        │                        │   └── audit_log        │
  │                        │◄── {verified: true} ───┤                       │
  │◄── "Verified!" ────────┤                        │                       │
```

### 7.2 Direct Subscription Flow (Without Verification)

```
User                  Flutter App              Cloud Functions           Firestore
  │                        │                        │                       │
  ├─ Tap "Subscribe" ─────►│                        │                       │
  │                        │  (No verification       │                       │
  │                        │   check — allowed!)     │                       │
  │                        ├── getPaymentConfig() ─►│                       │
  │                        │◄── {apiKey, price...} ─┤                       │
  │                        │                        │                       │
  │                        ├── UddoktaPay SDK       │                       │
  │◄── Payment WebView ───┤                        │                       │
  │                        │                        │                       │
  ├─ Complete payment ────►│                        │                       │
  │                        │◄── Result from SDK     │                       │
  │                        │                        │                       │
  │                        ├── createPaymentTx() ──►│                       │
  │                        │                        ├── Write payment_tx ──►│
  │                        │                        ├── processSub() ──────►│
  │                        │                        │   ├── user.subscribed  │
  │                        │                        │   ├── user.verified ✅ │
  │                        │                        │   ├── commission       │
  │                        │                        │   └── audit_log        │
  │                        │◄── {subscribed: true} ─┤                       │
  │◄── "Subscribed!" ──────┤                        │                       │
```

### 7.3 Pending Payment Flow (Admin Approval)

```
1. User completes payment but UddoktaPay returns "pending"
2. Flutter sends to createPaymentTransaction() with pending status
3. Cloud Function creates payment_transactions doc with status: "pending"
4. User sees "Payment pending" message
5. Admin sees pending payment in admin panel
6. Admin clicks "Approve" → adminApprovePayment()
7. Cloud Function updates status to "completed" and processes verification/subscription
8. User's account is now verified/subscribed
```

---

## 8. Sandbox ↔ Production Switch

### How to Switch

1. Go to Firebase Console → Firestore → `configurations/app_settings`
2. Navigate to `uddoktaPay` map
3. Change `isSandbox`:
   - `true` → Uses `sandbox.apiKey` and `sandbox.panelURL`
   - `false` → Uses `production.apiKey` and `production.panelURL`
4. Changes take effect within **30 seconds** (cache TTL)

### No Code Changes Required
The Cloud Function `getPaymentConfig` automatically selects the correct keys:
```typescript
const activeEnv = config.uddoktaPay.isSandbox
  ? config.uddoktaPay.sandbox
  : config.uddoktaPay.production;
```

### Sandbox Testing Checklist
- [ ] Set `isSandbox: true` in Firestore
- [ ] Use sandbox API key from UddoktaPay dashboard
- [ ] Use sandbox panel URL: `https://sandbox.uddoktapay.com`
- [ ] Test verification payment flow
- [ ] Test subscription payment flow (direct, without verification)
- [ ] Test pending payment → admin approval flow
- [ ] Test cancelled payment handling
- [ ] Verify commission distribution to uplines
- [ ] Check `app_funding_transactions` for undistributed entries

### Production Go-Live Checklist
- [ ] Get production API key from UddoktaPay
- [ ] Set `production.apiKey` in Firestore
- [ ] Set `production.panelURL` to `https://pay.uddoktapay.com`
- [ ] Set `isSandbox: false` in Firestore
- [ ] Test one real payment (small amount)
- [ ] Verify payment appears in UddoktaPay dashboard
- [ ] Verify Firestore documents are created correctly
- [ ] Monitor Cloud Function logs for errors

---

## 9. Commission Distribution Logic

### Verification Commission (10 Levels)

| Level | % of 125৳ | Reward Points | BDT Equivalent |
|-------|-----------|---------------|----------------|
| 1     | 25%       | 3,125         | ৳31.25         |
| 2     | 15%       | 1,875         | ৳18.75         |
| 3     | 12%       | 1,500         | ৳15.00         |
| 4     | 10%       | 1,250         | ৳12.50         |
| 5     | 8%        | 1,000         | ৳10.00         |
| 6     | 7%        | 875           | ৳8.75          |
| 7     | 6%        | 750           | ৳7.50          |
| 8     | 6%        | 750           | ৳7.50          |
| 9     | 6%        | 750           | ৳7.50          |
| 10    | 5%        | 625           | ৳6.25          |
| **Total** | **100%** | **12,500** | **৳125.00** |

### Subscription Commission (15 Levels)

| Level | % of 240৳ | Reward Points | BDT Equivalent |
|-------|-----------|---------------|----------------|
| 1     | 25%       | 6,000         | ৳60.00         |
| 2     | 15%       | 3,600         | ৳36.00         |
| 3     | 10%       | 2,400         | ৳24.00         |
| 4     | 8%        | 1,920         | ৳19.20         |
| 5     | 7%        | 1,680         | ৳16.80         |
| 6     | 6%        | 1,440         | ৳14.40         |
| 7     | 5%        | 1,200         | ৳12.00         |
| 8     | 4%        | 960           | ৳9.60          |
| 9     | 4%        | 960           | ৳9.60          |
| 10    | 3%        | 720           | ৳7.20          |
| 11    | 3%        | 720           | ৳7.20          |
| 12    | 2%        | 480           | ৳4.80          |
| 13    | 2%        | 480           | ৳4.80          |
| 14    | 1.5%      | 360           | ৳3.60          |
| 15    | 1.5%      | 360           | ৳3.60          |
| **Total** | **97%** | **24,000** | **৳240.00** |

> **Note:** Remaining 3% (subscription) and 50% (verification) of the total payment goes to SHIRAH platform.

### Undistributed Commission Rules

When distributing commission, each upline is checked:
1. **Missing upline** (null at that level) → Points logged to `app_funding_transactions`
2. **Unverified upline** (exists but not verified) → Points logged to `app_funding_transactions`
3. **Verified upline** → Receives reward points normally

This ensures:
- No commission is silently lost
- Admin can audit all undistributed amounts
- App funding pool grows from orphaned commissions

---

## 10. Google Play Compliance

### How SHIRAH Complies with Google Play Policies

| Policy | SHIRAH Implementation |
|--------|----------------------|
| **No MLM language** | UI shows "Reward Points earned for contribution", never "commission" or "level income" |
| **No pyramid scheme appearance** | Users never see network levels, percentages, or upline/downline structure |
| **Real value exchange** | Verification unlocks features (posting, withdrawal). Subscription gives premium access. |
| **No misleading claims** | UI says "One-time · Lifetime" — honest about what user pays for |
| **User sees earnings as rewards** | All commission appears as "Reward Points" not "cash" or "income" |
| **No mandatory recruitment** | Users can use the app without inviting others |
| **Payment transparency** | Clear pricing shown before payment, receipt via UddoktaPay |
| **No auto-renewal** | Both verification and subscription are one-time payments |

### UI Framing Rules
- ✅ "Premium Account" (not "Verification fee")
- ✅ "Pro Subscription" (not "MLM membership")
- ✅ "Reward Points earned for your contribution" (not "commission from downline")
- ✅ "One-time payment · Lifetime access" (clearly stated)
- ❌ Never show level numbers, percentages, or commission calculations

---

## 11. Troubleshooting

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| "Payment config error" | Firestore `app_settings` missing `uddoktaPay` | Add the config manually (Section 3) |
| API key is empty | `uddoktaPay.sandbox.apiKey` or `production.apiKey` not set | Add keys in Firestore |
| Payment completes but user not verified | Cloud Function error during `processVerification()` | Check Cloud Function logs, use admin approval |
| Duplicate payment error | Same `invoiceId` submitted twice | This is a safety check — normal behavior |
| Payment stuck as "pending" | UddoktaPay callback delayed or network issue | Admin can approve manually via `adminApprovePayment` |
| "User is already verified" | User trying to verify again | Normal — show info snackbar |
| SDK opens blank page | Wrong `panelURL` in Firestore | Verify the URL matches UddoktaPay environment |

### Checking Cloud Function Logs

```bash
# View payment function logs
firebase functions:log --only createPaymentTransaction

# View all payment-related logs
firebase functions:log | grep -i "payment"
```

### Verifying Firestore Data After Payment

Check these collections after a successful payment:
1. `payment_transactions` → New document with status "completed"
2. `users/{uid}` → `status.verified: true` and/or `status.subscription: "active"`
3. `reward_transactions` → Commission entries for uplines
4. `app_funding_transactions` → Entries for missing/unverified uplines
5. `audit_logs` → `user.verify` or `user.subscribe` entry

---

## 12. Security Checklist

### Before Going Live

- [ ] API keys are ONLY in Firestore, never in Flutter code
- [ ] Production API key is different from sandbox
- [ ] `isSandbox` is set to `false` in Firestore
- [ ] Cloud Functions deployed to `asia-south1`
- [ ] Firestore security rules block direct client writes to `payment_transactions`
- [ ] Firestore security rules block direct client writes to `configurations`
- [ ] Duplicate `invoiceId` check is working (tested)
- [ ] Admin approval flow is tested
- [ ] UddoktaPay webhook configured (optional but recommended)
- [ ] Cloud Function error monitoring enabled
- [ ] Test user `isTestUser` flag works for sandbox testing without real payments

### Firestore Security Rules (Ensure These Exist)

```
// payment_transactions — read-only for authenticated users (own documents)
match /payment_transactions/{transactionId} {
  allow read: if request.auth != null && resource.data.uid == request.auth.uid;
  allow write: if false; // Only Cloud Functions can write
}

// configurations — no client access
match /configurations/{configId} {
  allow read, write: if false; // Only Cloud Functions
}

// app_funding_transactions — no client access
match /app_funding_transactions/{docId} {
  allow read, write: if false; // Only Cloud Functions
}
```

---

**END OF UDDOKTAPAY SETUP GUIDE**
