# SHIRAH Payment System — Complete Reference

> **Last Updated:** February 21, 2026
> **Version:** 2.0 (Local SDK Fork + Production Fixes)
> **Status:** Production-Ready (Sandbox ✅ | Production ✅)

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Payment Flow (End-to-End)](#2-payment-flow-end-to-end)
3. [Firestore Configuration](#3-firestore-configuration)
4. [Local SDK Fork](#4-local-sdk-fork)
5. [Cloud Functions Reference](#5-cloud-functions-reference)
6. [Flutter Code Reference](#6-flutter-code-reference)
7. [Commission Distribution System](#7-commission-distribution-system)
8. [Firestore Data Schema](#8-firestore-data-schema)
9. [Error Handling & Edge Cases](#9-error-handling--edge-cases)
10. [Bug Fix History](#10-bug-fix-history)
11. [Google Play Policy Compliance](#11-google-play-policy-compliance)
12. [Setup Guide for New Developers](#12-setup-guide-for-new-developers)
13. [Non-Technical Admin Guide](#13-non-technical-admin-guide)
14. [Troubleshooting](#14-troubleshooting)

---

## 1. Architecture Overview

### System Diagram

```
┌──────────────────────────────────────────────────────────────────────┐
│                        FLUTTER APP (User)                            │
│                                                                      │
│  VerificationScreen → VerificationController → PaymentRepository     │
│         │                      │                       │             │
│         │            UddoktaPay SDK (local fork)       │             │
│         │            ┌──────────────────┐              │             │
│         └───────────→│ PaymentScreen    │              │             │
│                      │ (WebView)        │              │             │
│                      │   ↓              │              │             │
│                      │ ApiServices      │              │             │
│                      │   ↓              │              │             │
│                      │ verify payment   │              │             │
│                      └──────┬───────────┘              │             │
│                             │                          │             │
└─────────────────────────────┼──────────────────────────┼─────────────┘
                              │                          │
                    ┌─────────▼─────────┐    ┌───────────▼───────────┐
                    │  UddoktaPay API   │    │   Cloud Functions v2  │
                    │  (Payment Gateway)│    │   (asia-south1)       │
                    │                   │    │                       │
                    │ /api/checkout-v2  │    │ getPaymentConfig      │
                    │ /api/verify-payment│   │ createPaymentTransaction│
                    │ /checkout/{id}    │    │ processVerification   │
                    │ /checkout/cancel  │    │ processSubscription   │
                    └───────────────────┘    │ distributeRewards     │
                                             └───────────┬───────────┘
                                                         │
                                             ┌───────────▼───────────┐
                                             │   FIRESTORE           │
                                             │                       │
                                             │ configurations/       │
                                             │ payment_transactions/ │
                                             │ users/                │
                                             │ user_uplines/         │
                                             │ app_funding_txns/     │
                                             └───────────────────────┘
```

### Technology Stack

| Component | Technology | Region |
|-----------|-----------|--------|
| App | Flutter + GetX + ScreenUtil | — |
| Payment SDK | Local fork `packages/uddoktapay/` (v0.0.7) | — |
| Payment Gateway | UddoktaPay (bKash, Nagad, Rocket, Cards) | Bangladesh |
| Cloud Functions | Firebase Cloud Functions v2 (TypeScript) | asia-south1 |
| Database | Cloud Firestore | asia-south1 |
| Auth | Firebase Auth (Google, Email, Phone) | — |

### Key Domains

| Environment | Panel URL | Redirect URL |
|-------------|-----------|-------------|
| **Production** | `https://shirahsoft.paymently.io/` | `shirahsoft.paymently.io` |
| **Sandbox** | `https://sandbox.uddoktapay.com/` | `sandbox.uddoktapay.com` |

---

## 2. Payment Flow (End-to-End)

### Sequence Diagram

```
User            App                  UddoktaPay          Cloud Functions     Firestore
 │               │                      │                      │               │
 │─ Tap "Buy" ──→│                      │                      │               │
 │               │── getPaymentConfig ──→│                      │               │
 │               │                      │                      │── read ───────→│
 │               │←─── config data ─────│                      │←──────────────│
 │               │                      │                      │               │
 │               │── POST /checkout-v2 ─→│                      │               │
 │               │←── payment_url ──────│                      │               │
 │               │                      │                      │               │
 │               │── Open WebView ──────→│                      │               │
 │←── Payment page shown ──────────────│                      │               │
 │                                      │                      │               │
 │─── Select bKash, enter PIN ────────→│                      │               │
 │                                      │                      │               │
 │←── Redirect: ?invoice_id=XXX ──────│                      │               │
 │               │                      │                      │               │
 │               │── POST /verify ──────→│                      │               │
 │               │←── payment data ─────│                      │               │
 │               │                      │                      │               │
 │               │── createPaymentTxn ──→│                      │               │
 │               │                      │── write txn ────────→│               │
 │               │                      │── update user ──────→│               │
 │               │                      │── distribute RP ────→│               │
 │               │←── { success } ──────│                      │               │
 │               │                      │                      │               │
 │←── Success Dialog ──│                │                      │               │
```

### Step-by-Step Flow Detail

#### Phase 1: Config Loading
1. User opens Verification/Subscription screen
2. `VerificationController.onInit()` → `loadPaymentConfig()`
3. Calls `getPaymentConfig` Cloud Function
4. CF reads `configurations/app_settings` → selects sandbox or production keys
5. Returns: `{ isSandbox, apiKey, panelURL, redirectURL, verificationPriceBDT, subscriptionPriceBDT }`
6. Config stored in `paymentConfig` observable

#### Phase 2: Payment Initiation
1. User taps "Buy Verification" (250 BDT) or "Get Pro" (400 BDT)
2. Controller calls `_processPayment(type, amount)`
3. **Fresh config reload** (prevents stale sandbox/production flags)
4. Builds `CustomerDetails(fullName, email)` from `UserController`
5. Strips scheme from redirectURL → domain-only for WebView matching
6. Calls `UddoktaPay.createPayment()` with credentials

#### Phase 3: SDK Processing
1. SDK's `ApiServices.createPaymentRequest()`:
   - Normalizes `panelURL` (strips trailing slashes)
   - POST to `{panelURL}/api/checkout-v2`
   - Headers: `RT-UDDOKTAPAY-API-KEY: {apiKey}`
   - Body: `{ full_name, email, amount, metadata: {}, redirect_url, cancel_url, return_type: 'GET' }`
2. UddoktaPay API returns `{ payment_url }`
3. SDK opens `PaymentScreen` (WebView) with the payment URL

#### Phase 4: WebView Payment
1. User sees UddoktaPay checkout page (payment method selection)
2. User selects bKash/Nagad/Rocket/Card → completes payment
3. **On Success:** UddoktaPay redirects to `{redirect_url}?invoice_id=XXXXX`
4. **On Cancel:** UddoktaPay redirects to `{cancel_url}` (= `/checkout/cancel`)

#### Phase 5: Redirect Detection (Critical Logic)
```dart
// Cancel detection — exact path match
if (uri.path == '/checkout/cancel') → Navigator.pop(context) → canceled

// Success detection — THREE conditions must ALL be true:
//   1. URL has non-empty `invoice_id` query parameter
//   2. Host matches redirect domain
//   3. URL path does NOT contain `/checkout/` or `/payment/`
if (hasInvoiceId && hostMatchesRedirect && !isCheckoutPage) → verify payment
```

**Why this is critical:** In production, the payment panel domain (`shirahsoft.paymently.io`) is the SAME as the redirect domain. Without the `invoice_id` + path exclusion checks, the WebView would trigger verification on every checkout page navigation.

#### Phase 6: Payment Verification
1. SDK calls `ApiServices.verifyPayment(invoiceId)`
2. POST to `{panelURL}/api/verify-payment` with `{ invoice_id }`
3. Returns payment details: amount, fee, method, senderNumber, transactionId, status
4. SDK pops WebView with `RequestResponse` result

#### Phase 7: Backend Processing
1. Controller receives `RequestResponse` with status `completed`/`pending`/`canceled`
2. **For completed:** Calls `createPaymentTransaction` CF with camelCase payload
3. CF validates → stores in `payment_transactions` → calls `processVerification()` or `processSubscription()`
4. Process function: sets `verified=true` / `subscription=active` → distributes commission RP → writes undistributed entries → audit log
5. Controller refreshes user → shows `PaymentResultDialog`

#### Phase 8: Result Display
- **Success:** Lottie animation + user profile picture + name + verification/subscription badges + transaction details
- **Pending:** Info icon + message + transaction ID
- **Failed:** Error icon + retry button (re-invokes `_processPayment`)
- **Cancelled:** Warning icon + retry button + close button

---

## 3. Firestore Configuration

### Document: `configurations/app_settings`

```javascript
{
  uddoktaPay: {
    isSandbox: false,  // Toggle sandbox/production

    sandbox: {
      apiKey: "982d381360a69d419689740d9f2e26ce36fb7a50",
      panelURL: "https://sandbox.uddoktapay.com/",
      redirectURL: "sandbox.uddoktapay.com"
    },

    production: {
      apiKey: "aeAjB5YSDRVymoDShYQ4GINkLCmPCbwiZoZqwX4P",
      panelURL: "https://shirahsoft.paymently.io/",
      redirectURL: "shirahsoft.paymently.io"
    }
  },

  verification: {
    priceBDT: 250,
    rewardDistributedBDT: 125,      // 50% goes to uplines
    totalRewardPoints: 12500,        // 125 × 100
    levelDistribution: [
      { level: 1, percent: 20.00, points: 2500 },
      { level: 2, percent: 10.00, points: 1250 },
      { level: 3, percent: 5.00,  points: 625 },
      { level: 4, percent: 3.00,  points: 375 },
      { level: 5, percent: 2.50,  points: 312 },
      { level: 6, percent: 2.00,  points: 250 },
      { level: 7, percent: 2.00,  points: 250 },
      { level: 8, percent: 2.00,  points: 250 },
      { level: 9, percent: 1.75,  points: 219 },
      { level: 10, percent: 1.75, points: 219 }
    ]
  },

  subscription: {
    priceBDT: 400,
    rewardDistributedBDT: 240,      // 60% goes to uplines
    totalRewardPoints: 24000,
    levelDistribution: [
      { level: 1,  percent: 15.00, points: 3600 },
      { level: 2,  percent: 8.00,  points: 1920 },
      { level: 3,  percent: 5.00,  points: 1200 },
      { level: 4,  percent: 4.00,  points: 960 },
      { level: 5,  percent: 3.50,  points: 840 },
      { level: 6,  percent: 3.00,  points: 720 },
      { level: 7,  percent: 2.50,  points: 600 },
      { level: 8,  percent: 2.50,  points: 600 },
      { level: 9,  percent: 2.25,  points: 540 },
      { level: 10, percent: 2.25,  points: 540 },
      { level: 11, percent: 2.00,  points: 480 },
      { level: 12, percent: 2.00,  points: 480 },
      { level: 13, percent: 2.00,  points: 480 },
      { level: 14, percent: 3.00,  points: 720 },
      { level: 15, percent: 3.00,  points: 720 }
    ]
  },

  network: {
    maxDepth: 15,
    verificationDepth: 10
  }
}
```

### Critical Firestore Rules

| Field | Format | Notes |
|-------|--------|-------|
| `panelURL` | Full URL with trailing slash | SDK normalizes it (strips trailing slash for API) |
| `redirectURL` | **Domain only, no scheme** | e.g. `shirahsoft.paymently.io` NOT `https://...` |
| `apiKey` | String | Different for sandbox/production |
| `isSandbox` | Boolean | `true` = sandbox, `false` = production |

**⚠️ WARNING:** Changing `isSandbox` affects ALL users immediately. Always test in sandbox before switching to production.

---

## 4. Local SDK Fork

### Why We Forked

The pub.dev `uddoktapay` package (v0.0.6) had critical production bugs:

| Bug | Impact | Fix |
|-----|--------|-----|
| No trailing slash normalization on `panelURL` | `https://domain.io/` → `https://domain.io//api/checkout-v2` (404) | `_normalizeBaseUrl()` strips trailing slashes |
| `redirect_url` in API body needs `https://` but WebView matching needs domain-only | WebView: `uri.host.contains()` never matches if redirectURL has scheme | `_ensureScheme()` for API body; domain-only for WebView |
| `cancel_url` constructed wrong | `{panelURL}checkout/cancel` missing middle slash or doubled | Proper construction: `${normalizedUrl}/checkout/cancel` |
| Sandbox fallback used hardcoded `programmingwormhole.com` | "Forbidden" page on redirect | Always pass credentials (even sandbox) |
| Host-only redirect detection | Matches ALL pages when panel domain = redirect domain | Require `invoice_id` param + exclude checkout paths |

### Fork Location

```
packages/uddoktapay/
├── lib/
│   ├── uddoktapay.dart              ← Entry point
│   ├── controllers/
│   │   └── payment_controller.dart  ← GetX state
│   ├── core/
│   │   └── services/
│   │       └── api_services.dart    ← HTTP calls + URL normalization
│   ├── models/
│   │   ├── credentials.dart         ← UddoktapayCredentials
│   │   ├── customer_model.dart      ← CustomerDetails
│   │   └── request_response.dart    ← RequestResponse + ResponseStatus
│   ├── utils/
│   │   ├── config.dart              ← Sandbox defaults
│   │   └── endpoints.dart           ← API paths
│   ├── views/
│   │   └── payment_screen.dart      ← WebView + shimmer loading
│   └── widget/
│       └── custom_snackbar.dart     ← SDK snackbar helper
└── pubspec.yaml                     ← v0.0.7 local
```

### Key Fixes in Fork

#### URL Normalization (`api_services.dart`)
```dart
static String _normalizeBaseUrl(String url) {
  return url.replaceAll(RegExp(r'/+$'), '');  // Strip trailing slashes
}

static String _ensureScheme(String url) {
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    return 'https://$url';
  }
  return url;
}
```

#### Redirect Detection (`payment_screen.dart`)
```dart
// Cancel — exact path match
if (uri.path == cleanCancelPath) → cancel

// Success — ALL three conditions required:
final hasInvoiceId = invoiceId != null && invoiceId.isNotEmpty;
final isCheckoutPage = uri.path.contains('/checkout/') || uri.path.contains('/payment/');
final hostMatchesRedirect = uri.host == cleanRedirect || uri.host.endsWith('.$cleanRedirect');

if (hasInvoiceId && hostMatchesRedirect && !isCheckoutPage) → verify
```

### pubspec.yaml Integration
```yaml
# In project root pubspec.yaml:
dependencies:
  uddoktapay:
    path: packages/uddoktapay  # Local fork instead of pub.dev v0.0.6
```

---

## 5. Cloud Functions Reference

### 5.1 `getPaymentConfig`
| Property | Value |
|----------|-------|
| **Type** | `onCall` (v2) |
| **Region** | `asia-south1` |
| **Auth** | Required (any authenticated user) |
| **Parameters** | None |
| **Returns** | `{ success, message, data: { isSandbox, apiKey, panelURL, redirectURL, verificationPriceBDT, subscriptionPriceBDT } }` |
| **Cache** | 30-second server-side cache |

**What it does:**
1. Reads `configurations/app_settings` from Firestore
2. Checks `uddoktaPay.isSandbox` flag
3. Returns the active environment's keys + prices

### 5.2 `createPaymentTransaction`
| Property | Value |
|----------|-------|
| **Type** | `onCall` (v2) |
| **Region** | `asia-south1` |
| **Auth** | Required |
| **Parameters** | `{ type: "verification" \| "subscription", uddoktapayResponse: { fullName, email, amount, fee, chargedAmount, invoiceId, paymentMethod, senderNumber, transactionId, date, status } }` |
| **Returns** | `{ success, message, data: { paymentTransactionId, verified?, subscribed? } }` |

**What it does:**
1. Validates auth + payment type
2. Checks user not already verified/subscribed
3. Checks duplicate `invoiceId` (prevents double-processing)
4. Maps UddoktaPay status string → internal enum
5. Creates `payment_transactions/{id}` document
6. If status = `COMPLETED`:
   - Calls `processVerification()` or `processSubscription()`
   - These set user flags + distribute commission RP
7. Returns result

### 5.3 `adminApprovePayment`
| Property | Value |
|----------|-------|
| **Type** | `onCall` (v2) |
| **Auth** | Admin with `payment.approve` permission (SuperAdmin bypasses) |
| **Parameters** | `{ paymentTransactionId: string }` |
| **Returns** | `{ success, message }` |

**What it does:**
1. Validates admin permissions
2. Loads payment document, checks status is `pending`
3. Updates status to `completed`
4. Calls `processVerification`/`processSubscription`
5. Writes audit log entry

### 5.4 `getPaymentHistory`
| Property | Value |
|----------|-------|
| **Auth** | Required |
| **Parameters** | `{ limit?: number (default 20), startAfter?: string }` |
| **Returns** | `{ success, data: PaymentTransaction[] }` |

### 5.5 `getAdminPaymentTransactions`
| Property | Value |
|----------|-------|
| **Auth** | Admin with `payment.approve` |
| **Parameters** | `{ limit?, status?, type? }` |
| **Returns** | `{ success, data: PaymentTransaction[] }` |

### 5.6 Internal Functions (not directly callable)

#### `processVerification(uid, paymentTransactionId)` 
1. Firestore transaction:
   - Set `users/{uid}.status.verified = true`
   - Grant verification permissions
   - Increment `user_network_stats` for upline chain
2. Distribute verification rewards (10 levels)
3. Write undistributed entries to `app_funding_transactions`
4. Audit log

#### `processSubscription(uid, paymentTransactionId)`
1. Same as above but also:
   - Set `users/{uid}.status.subscription = 'active'`
   - Auto-verifies if not already verified
   - Distribute subscription rewards (15 levels)

#### `distributeVerificationRewards(descendantUid, uplines)`
See Section 7.

#### `distributeSubscriptionRewards(descendantUid, uplines)`
See Section 7.

---

## 6. Flutter Code Reference

### 6.1 VerificationController

**File:** `lib/features/verification/controllers/verification_controller.dart`

```dart
class VerificationController extends GetxController {
  static VerificationController get instance => Get.find();

  // State
  final RxBool isLoading = false.obs;
  final Rx<Map<String, dynamic>> paymentConfig = Rx({});
  final RxnString configError = RxnString(null);

  // Config getters
  bool get isSandboxMode;
  String get uddoktaPayApiKey;
  String get uddoktaPayPanelURL;
  String get uddoktaPayRedirectURL;
  double get verificationPrice;  // default 250.0
  double get subscriptionPrice;  // default 400.0
  bool get hasConfig;

  // Actions
  Future<void> purchaseVerification();
  Future<void> purchaseSubscription();

  // Internal
  Future<void> _processPayment({type, amount});
  Future<void> _handlePaymentSuccess({type, paymentResult});
  Future<void> _handlePaymentPending({type, paymentResult});
  Future<void> _handlePaymentFailure(paymentResult, {type, amount});
  Map<String, dynamic> _buildCamelCasePayload(RequestResponse result);
}
```

**Key design decisions:**
- Always refreshes config before each payment (`loadPaymentConfig()`)
- Always passes `UddoktapayCredentials` to SDK (even sandbox)
- Strips scheme from `redirectURL` before passing to SDK
- Converts SDK's snake_case response to camelCase for Cloud Functions
- Passes `onRetry` callback to failure dialog → re-invokes `_processPayment`

### 6.2 PaymentResultDialog

**File:** `lib/features/verification/views/widgets/payment_result_dialog.dart`

```dart
enum PaymentResultType { success, failed, cancelled, pending }

class PaymentResultDialog extends StatelessWidget {
  static Future<void> show({
    required PaymentResultType type,
    required String title,
    required String message,
    String? paymentType,        // 'verification' or 'subscription'
    String? transactionId,
    String? amount,
    String? paymentMethod,
    VoidCallback? onPrimaryAction,
    VoidCallback? onRetry,       // Re-invokes payment flow
    String? primaryActionText,
  });
}
```

**Design:** Material 3, dark/light theme support, 4 states:
- **Success:** Lottie animation + colored header banner + user profile card (avatar, name, verification & subscription badges) + transaction details
- **Failed:** Animated error icon + retry button → closes dialog and calls `onRetry`
- **Cancelled:** Warning icon + retry button + close button
- **Pending:** Info icon + transaction details + done button

### 6.3 PaymentRepository

**File:** `lib/data/repositories/payment_repository.dart`

```dart
class PaymentRepository {
  Future<Map<String, dynamic>> createPaymentTransaction({type, uddoktapayResponse});
  Future<Map<String, dynamic>> getPaymentConfig();
  Future<List<PaymentTransactionModel>> getPaymentHistory({limit, startAfter});
  Future<Map<String, dynamic>> verifyUser({paymentTransactionId});
  Future<Map<String, dynamic>> subscribeUser({paymentTransactionId});
}
```
All methods call `CloudFunctionsService.instance` → `FirebaseFunctions.instanceFor(region: 'asia-south1')`.

---

## 7. Commission Distribution System

### How It Works

When a user completes a payment (verification or subscription), the system distributes a portion of the payment as Reward Points to the user's upline chain.

**Conversion rate:** 100 Reward Points = 1 BDT

### Verification Commission (250 BDT)

| Component | Amount | Percentage |
|-----------|--------|------------|
| **To uplines (RP)** | ৳125 (12,500 RP) | 50% |
| **To platform** | ৳125 | 50% |

| Level | % of Price | BDT | Reward Points |
|-------|-----------|-----|---------------|
| 1 | 20.00% | ৳50.00 | 2,500 |
| 2 | 10.00% | ৳25.00 | 1,250 |
| 3 | 5.00% | ৳12.50 | 625 |
| 4 | 3.00% | ৳7.50 | 375 |
| 5 | 2.50% | ৳6.25 | 312 |
| 6 | 2.00% | ৳5.00 | 250 |
| 7 | 2.00% | ৳5.00 | 250 |
| 8 | 2.00% | ৳5.00 | 250 |
| 9 | 1.75% | ৳4.38 | 219 |
| 10 | 1.75% | ৳4.38 | 219 |
| **Total** | **50.00%** | **৳125.00** | **12,500** |

### Subscription Commission (400 BDT)  

| Component | Amount | Percentage |
|-----------|--------|------------|
| **To uplines (RP)** | ৳240 (24,000 RP) | 60% |
| **To platform** | ৳160 | 40% |

| Level | % of Price | BDT | Reward Points |
|-------|-----------|-----|---------------|
| 1 | 15.00% | ৳60.00 | 3,600 |
| 2 | 8.00% | ৳32.00 | 1,920 |
| 3 | 5.00% | ৳20.00 | 1,200 |
| 4 | 4.00% | ৳16.00 | 960 |
| 5 | 3.50% | ৳14.00 | 840 |
| 6 | 3.00% | ৳12.00 | 720 |
| 7 | 2.50% | ৳10.00 | 600 |
| 8 | 2.50% | ৳10.00 | 600 |
| 9 | 2.25% | ৳9.00 | 540 |
| 10 | 2.25% | ৳9.00 | 540 |
| 11 | 2.00% | ৳8.00 | 480 |
| 12 | 2.00% | ৳8.00 | 480 |
| 13 | 2.00% | ৳8.00 | 480 |
| 14 | 3.00% | ৳12.00 | 720 |
| 15 | 3.00% | ৳12.00 | 720 |
| **Total** | **60.00%** | **৳240.00** | **24,000** |

### Undistributed Rewards

If an upline at a given level is **missing** or **unverified**, their commission is NOT redistributed. Instead, it's logged as an "undistributed" entry in `app_funding_transactions`:

```javascript
{
  type: "undistributed_reward",
  sourceUid: "the_buyer_uid",
  sourceEvent: "verification" | "subscription",
  skippedLevel: 3,
  skippedUplineUid: "uid_or_null",
  reason: "missing_upline" | "unverified_upline",
  points: 625,
  amountBDT: 6.25,
  createdAt: Timestamp
}
```

This creates a transparent audit trail and allows the platform to track potential revenue recovery.

---

## 8. Firestore Data Schema

### 8.1 `configurations/app_settings`
See Section 3 for full structure.

### 8.2 `payment_transactions/{id}`

```javascript
{
  id: "auto_generated",
  uid: "firebase_auth_uid",
  type: "verification" | "subscription",
  amount: "250.00",
  status: "completed" | "pending" | "canceled" | "failed",
  paymentMethod: "bKash" | "Nagad" | "Rocket" | ...,
  invoiceId: "uddoktapay_invoice_id",
  transactionId: "gateway_txn_id",
  senderNumber: "01XXXXXXXXX",
  fee: "0.00",
  chargedAmount: "250.00",
  uddoktapayResponse: { /* full raw response */ },
  processedBy: "system" | "admin_uid",
  processedAt: Timestamp | null,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### 8.3 `users/{uid}` (payment-relevant fields)

```javascript
{
  status: {
    verified: true | false,
    subscription: "active" | "none",
    accountState: "active" | "suspended"
  },
  wallet: {
    balance: 0.00,          // BDT, withdrawable
    rewardPoints: 12500     // RP, convertible at 100:1 BDT
  }
}
```

### 8.4 `user_uplines/{uid}`

```javascript
{
  u1: "direct_inviter_uid",
  u2: "inviter_of_inviter_uid",
  u3: "...",
  // ... up to u15
  u15: "uid_or_null",
  maxDepth: 15,
  createdAt: Timestamp
}
```

### 8.5 `app_funding_transactions/{id}`
See "Undistributed Rewards" in Section 7.

---

## 9. Error Handling & Edge Cases

### Common Errors

| Error | Cause | Resolution |
|-------|-------|------------|
| "Could not load payment configuration" | Config not in Firestore or CF failed | Check `configurations/app_settings` exists with correct structure |
| "The invoice id field is required" | Redirect detected on wrong page (checkout/process URL) | Fixed in SDK fork — requires `invoice_id` param + not checkout page |
| 404 on API endpoint | Double slash in URL from trailing slash | Fixed in SDK fork — `_normalizeBaseUrl()` |
| "Forbidden" page in WebView | Sandbox using `programmingwormhole.com` as redirect | Fixed — always pass credentials |
| Empty `invoice_id` after redirect | WebView matched host but not the actual redirect URL | Fixed — require non-empty `invoice_id` AND exclude checkout paths |
| `Map<Object?, Object?>` cast error | Firebase nested map type mismatch | `Map<String, dynamic>.from(rawData as Map)` |
| Snake_case payload but CF expects camelCase | SDK `toJson()` vs CF parameter names | `_buildCamelCasePayload()` mapping |

### Edge Cases Handled

1. **User already verified** → Snackbar "Already verified", no payment triggered
2. **User already subscribed** → Snackbar "Already active", no payment triggered  
3. **Duplicate invoiceId** → CF rejects with "duplicate payment" error
4. **Config changes mid-session** → Fresh config reload before every payment
5. **WebView dismiss without completing** → Returns `canceled` status
6. **CF returns `success: false`** → Shows "pending" dialog (rare edge case)
7. **Network error during verification** → Catches exception, pops WebView
8. **Missing upline in chain** → Reward logged as undistributed, not lost

---

## 10. Bug Fix History

### Round 1-3: Initial Setup
- Created Cloud Function structure for payment processing
- Implemented UddoktaPay SDK integration
- Fixed Firestore document structure

### Round 4-5: Runtime Fixes
- **EasyLoading blocking WebView** → Moved loading to AFTER WebView closes
- **Stale `isSandbox` value** → Fresh config reload before every payment

### Round 6-7: URL & Response Fixes
- **Missing `https://` on redirectURL** → Auto-prefix for API body
- **`ResponseStatus` enum serialization** → Created `_responseStatusToString()`

### Round 8: Config Error Handling
- **Silent error swallowing** → `configError` RxnString + meaningful error messages

### Round 9: Payload Mismatch
- **Snake_case → camelCase mismatch** → `_buildCamelCasePayload()`

### Round 10: Firebase Type Casting
- **`Map<Object?, Object?>` from Firebase** → `Map<String, dynamic>.from()`

### Round 11: SDK Fork Created
- **Production 404 from doubled path** → Local fork with `_normalizeBaseUrl()`
- **Cancel URL construction** → Proper slash handling

### Round 12: Sandbox Forbidden Fix
- **`programmingwormhole.com` redirect** → Always pass credentials to SDK

### Round 13: Production Redirect Detection (CRITICAL)
- **"invoice_id field is required"** → Panel domain = redirect domain caused premature matching
- **Fix:** Require non-empty `invoice_id` + host matches + NOT a checkout/payment page

### Round 14: UI Modernization
- **Plain CircularProgressIndicator** → Shimmer-style loading overlay with animated gradient
- **No verifying state** → Added "Verifying Payment..." overlay

### Round 15: Dialog & Retry
- **Rebuilt `PaymentResultDialog`** → Material 3 design with user profile, status badges, Lottie
- **"Try Again" button did nothing** → Now passes `onRetry` callback that re-invokes `_processPayment`

---

## 11. Google Play Policy Compliance

### Summary

| Area | Status | Priority |
|------|--------|----------|
| Payments (Google Play Billing) | ⚠️ RISK | 🔴 Critical |
| Financial Services | ⚠️ RISK | 🟡 High |
| MLM / Pyramid Detection | ⚠️ RISK | 🔴 Critical |
| User Data & Privacy | ⚠️ RISK | 🔴 Critical |
| WebView Payment | ✅ Compliant | 🟢 Low |
| Misleading Claims | ⚠️ RISK | 🟡 High |
| Permissions | ✅ Compliant | 🟢 Low |
| Content Rating | ✅ Compliant | 🟢 Low |

### Top 5 Action Items Before Submission

1. **Privacy Policy + Account Deletion** — Create hosted privacy policy; implement `deleteMyAccount` Cloud Function
2. **Reframe as real-world services** — Add genuine KYC to verification; frame subscription as business account
3. **Reduce commission levels** — Cap at 3-5 levels; rename backend terminology (upline → referrer, commission → referralReward)
4. **Rewrite messaging** — "Earn rewards" not "earn money"; lead Play Store listing with business services
5. **Complete Data Safety Section** — Declare all data collection accurately

### Detailed Analysis

See the full audit report in `documents/uddoktaPay/GOOGLE_PLAY_POLICY_AUDIT.md`.

---

## 12. Setup Guide for New Developers

### Prerequisites

1. Flutter SDK (latest stable)
2. Firebase project configured with Firestore + Cloud Functions
3. UddoktaPay merchant account (for production API key)

### Step 1: Firestore Setup

Create `configurations/app_settings` document with the structure in Section 3. Start with `isSandbox: true`.

### Step 2: Deploy Cloud Functions

```bash
cd functions
npm install
npm run deploy
# Deploys: getPaymentConfig, createPaymentTransaction, adminApprovePayment,
#           getPaymentHistory, getAdminPaymentTransactions,
#           verifyUserProfile, subscribeUser
```

### Step 3: Flutter Dependencies

The local SDK fork is already in `packages/uddoktapay/`. No additional setup needed — `flutter pub get` handles it via the `path:` dependency.

### Step 4: Test in Sandbox

1. Ensure `isSandbox: true` in Firestore
2. Use sandbox API key: `982d381360a69d419689740d9f2e26ce36fb7a50`
3. sandbox panelURL: `https://sandbox.uddoktapay.com/`
4. Sandbox supports test payments with any bKash/Nagad number
5. Use sandbox card: `4242 4242 4242 4242`, Exp: `12/34`, CVV: `123`

### Step 5: Switch to Production

1. Set `isSandbox: false` in Firestore  
2. Ensure production keys are correct:
   - API Key from UddoktaPay merchant dashboard
   - Panel URL: `https://shirahsoft.paymently.io/` (with trailing slash)
   - Redirect URL: `shirahsoft.paymently.io` (domain only, NO scheme)
3. Test with a real small payment first

### Step 6: Register Controller

Ensure `VerificationController` is registered in `InitialBinding`:
```dart
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => VerificationController());
    // ... other controllers
  }
}
```

---

## 13. Non-Technical Admin Guide

### Switching Between Sandbox and Production

1. Go to **Firebase Console** → **Firestore Database**
2. Navigate to `configurations` → `app_settings`
3. Find the `uddoktaPay` map
4. Change `isSandbox`:
   - `true` → Sandbox mode (test payments, no real money)
   - `false` → Production mode (real payments)
5. Change takes effect on users' next payment attempt

### Approving Pending Payments

Some payments may arrive as "pending" if the payment gateway doesn't confirm immediately.

1. Open the Admin Panel
2. Go to **Payments** section
3. Find pending payments
4. Click **Approve** → This will:
   - Set payment status to "completed"
   - Verify or subscribe the user
   - Distribute commission Reward Points to their upline chain
   - Create audit log entry

### Changing Prices

1. In Firestore, update `configurations/app_settings`:
   - `verification.priceBDT` → New verification price
   - `subscription.priceBDT` → New subscription price
2. Also update the `levelDistribution` arrays to match if changing percentage splits
3. Redeploy Cloud Functions if the config cache is stale

### Monitoring Payments

- `payment_transactions` collection shows all payments
- `app_funding_transactions` shows undistributed rewards
- Filter by `status`, `type`, `uid` for specific queries

### Viewing Commission Distribution

For any payment:
1. Find the `payment_transactions` document
2. Check `user_uplines/{buyer_uid}` to see the upline chain
3. Cross-reference with `rewardPoints` increases on upline user docs
4. Check `app_funding_transactions` for any undistributed entries from that payment

---

## 14. Troubleshooting

### "Could not load payment configuration"

**Causes:**
- `configurations/app_settings` document doesn't exist in Firestore
- `uddoktaPay` map missing or malformed
- Cloud Function `getPaymentConfig` not deployed
- Network error

**Fix:** Verify Firestore document exists with correct structure. Redeploy CFs if needed.

### "The invoice id field is required" (Production)

**Cause:** The WebView redirect detection triggered on a checkout page instead of the actual redirect.

**Was Fixed In:** SDK fork v0.0.7 — redirect now requires non-empty `invoice_id` query parameter AND the URL must NOT be a checkout/process page.

### Payment WebView Shows "Forbidden"

**Cause:** SDK using hardcoded `programmingwormhole.com` for redirect URLs.

**Was Fixed In:** Controller always passes `UddoktapayCredentials` to SDK, never `null`.

### Payment Succeeds in Gateway But App Shows "Failed"

**Possible Causes:**
1. `verifyPayment` API call failed → Check internet connection
2. `invoice_id` was empty in redirect → Check redirect URL in WebView logs
3. `redirectURL` in Firestore has `https://` prefix → Must be domain-only

**How to recover:** Use admin panel to find the `payment_transactions` doc (if created) or manually approve if the payment was real.

### "Try Again" Button Doesn't Work

**Was Fixed In:** The `onRetry` callback now closes the dialog via `Get.back()` and re-invokes `_processPayment(type, amount)`.

### Commission Not Distributed

**Possible Causes:**
1. Upline at that level doesn't exist → Logged as `missing_upline` in `app_funding_transactions`
2. Upline is not verified → Logged as `unverified_upline`
3. `user_uplines` document missing for buyer → Chain lookup fails

**Fix:** Check `app_funding_transactions` for `undistributed_reward` entries from that payment.

### Double Payment Processing

**Protection:** Cloud Function checks for duplicate `invoiceId` before creating transaction. If a second call arrives with the same `invoiceId`, it's rejected.

---

## Related Documents

- [PAYMENT_SYSTEM_DOCUMENTATION.md](PAYMENT_SYSTEM_DOCUMENTATION.md) — Detailed technical docs (original)
- [UDDOKTAPAY_SETUP_GUIDE.md](UDDOKTAPAY_SETUP_GUIDE.md) — Setup and configuration guide (original)
- [GOOGLE_PLAY_POLICY_AUDIT.md](GOOGLE_PLAY_POLICY_AUDIT.md) — Full policy compliance audit

---

*This document is the unified reference for the entire shirah payment system. For changes, update this document alongside the code.*
