# UddoktaPay Payment System — Complete Documentation

> **Last Updated:** Session 3 (Full Audit + Re-Verify Mechanism)  
> **Project:** SHIRAH (shirahsoft)  
> **Region:** asia-south1

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Architecture](#architecture)
3. [Payment Flow — Step by Step](#payment-flow--step-by-step)
4. [UddoktaPay Configuration](#uddoktapay-configuration)
5. [Cloud Functions Reference](#cloud-functions-reference)
6. [Flutter Layer](#flutter-layer)
7. [Local SDK Fork](#local-sdk-fork)
8. [Webhook (IPN) System](#webhook-ipn-system)
9. [Re-Verify Mechanism](#re-verify-mechanism)
10. [Status Handling](#status-handling)
11. [Commission Distribution](#commission-distribution)
12. [Security](#security)
13. [Troubleshooting](#troubleshooting)

---

## System Overview

SHIRAH uses **UddoktaPay** as its Bangladeshi local payment gateway for:

- **Account Verification** — One-time payment (250 BDT default)
- **Pro Subscription** — One-time lifetime payment (400 BDT default)

The system supports **sandbox** and **production** modes, toggled via Firestore config.

### Key URLs

| Resource | URL |
|----------|-----|
| Production Panel | `https://shirahsoft.paymently.io/` |
| Sandbox Panel | `https://sandbox.uddoktapay.com/` |
| Webhook Endpoint | `https://uddoktapaywebhook-mik7xom3ca-el.a.run.app` |
| Firebase Console | `https://console.firebase.google.com/project/shirahsoft/` |

### API Endpoints (relative to panel URL)

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/checkout-v2` | POST | Create a payment |
| `/api/verify-payment` | POST | Verify a payment by invoice_id |
| `/api/refund-payment` | POST | Refund a payment |

### API Key Abilities

The production API key has these abilities:
- `payment:checkout` — Create new payments
- `payment:verify` — Verify payment status
- `payment:refund` — Refund payments

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    FLUTTER APP                          │
│                                                         │
│  VerificationController                                 │
│    ├── loadPaymentConfig() → getPaymentConfig CF        │
│    ├── purchaseVerification() → _processPayment()       │
│    ├── purchaseSubscription() → _processPayment()       │
│    └── _checkPendingPaymentStatus()                     │
│                    │                                    │
│              PaymentRepository                          │
│                    │                                    │
│            CloudFunctionsService                        │
└────────────────────┼────────────────────────────────────┘
                     │ HTTPS Callable
┌────────────────────┼────────────────────────────────────┐
│              CLOUD FUNCTIONS                            │
│                                                         │
│  createPaymentTransaction ──► processVerification       │
│  adminApprovePayment      ──► processSubscription       │
│  reVerifyPendingPayment   ──► (auto-process)            │
│  getPaymentConfig                                       │
│  getPaymentHistory                                      │
│  getAdminPaymentTransactions                            │
│                                                         │
│  uddoktapayWebhook (HTTP) ──► (auto-process)            │
└────────────────────┼────────────────────────────────────┘
                     │
┌────────────────────┼────────────────────────────────────┐
│              FIRESTORE                                  │
│                                                         │
│  configurations/app_settings                            │
│    └── uddoktaPay (config)                              │
│  payment_transactions/{id}                              │
│  users/{uid}                                            │
│    └── status.verified / status.subscription            │
│  audit_logs/{id}                                        │
└─────────────────────────────────────────────────────────┘
```

---

## Payment Flow — Step by Step

### Happy Path (Instant Completion)

```
1. User taps "Verify Account" or "Get Pro"
2. Controller calls getPaymentConfig CF → gets API key, panel URL, prices
3. Controller creates UddoktaPay checkout via SDK:
   - Sends: amount, customer info, metadata, webhook_url, redirect_url
   - UddoktaPay returns: checkout URL
4. SDK opens WebView → user pays via bKash/Nagad/Rocket/etc.
5. Payment completes → UddoktaPay redirects to redirect_url
6. SDK detects redirect → calls verify-payment API → returns response
7. SDK returns RequestResponse with status=COMPLETED
8. Controller calls createPaymentTransaction CF:
   - Creates payment_transactions doc
   - Calls processVerification/processSubscription
   - Distributes commission to uplines
   - Returns { success: true, data: { paymentTransactionId, verified/subscribed } }
9. Controller refreshes user → shows success dialog
```

### SMS/Manual Payment Path (Pending → Completed)

```
1. User taps "Verify Account" or "Get Pro"
2-4. Same as above
5. User pays via SMS banking (e.g., Dbbl, bank transfer)
6. UddoktaPay receives SMS data → shows "Awaiting Review" with matched transaction ID
7. SDK detects redirect → calls verify-payment API → status=PENDING
8. SDK returns RequestResponse with status=PENDING
9. Controller calls createPaymentTransaction CF:
   - Creates payment_transactions doc with status=PENDING
   - Does NOT call processVerification/processSubscription
10. Controller shows pending dialog with "Check Status" button

--- User waits ---

11a. UddoktaPay admin approves SMS Data → UddoktaPay sends webhook
     → uddoktapayWebhook CF auto-processes → user verified/subscribed

11b. User taps "Check Status" → reVerifyPendingPayment CF
     → Calls UddoktaPay verify-payment API
     → If COMPLETED → auto-processes → user verified/subscribed
     → If still PENDING → shows "still pending" message
```

---

## UddoktaPay Configuration

### Firestore Path

```
configurations/app_settings → uddoktaPay
```

### Structure

```json
{
  "uddoktaPay": {
    "isSandbox": false,
    "production": {
      "apiKey": "aeAjB5YSDRVymoDShYQ4GINkLCmPCbwiZoZqwX4P",
      "panelURL": "https://shirahsoft.paymently.io/",
      "redirectURL": "shirahsoft.paymently.io",
      "webhookURL": "https://uddoktapaywebhook-mik7xom3ca-el.a.run.app"
    },
    "sandbox": {
      "apiKey": "982d381360a69d419689740d9f2e26ce36fb7a50",
      "panelURL": "https://sandbox.uddoktapay.com/",
      "redirectURL": "",
      "webhookURL": ""
    }
  }
}
```

### Switching Modes

- Set `isSandbox: true` for testing
- Set `isSandbox: false` for production
- Both environments are fully independent

---

## Cloud Functions Reference

### 1. `getPaymentConfig` (onCall)

Returns payment configuration for the Flutter app.

**Returns:**
```json
{
  "success": true,
  "data": {
    "isSandbox": false,
    "apiKey": "...",
    "panelURL": "https://shirahsoft.paymently.io/",
    "redirectURL": "shirahsoft.paymently.io",
    "webhookURL": "https://uddoktapaywebhook-mik7xom3ca-el.a.run.app",
    "verificationPriceBDT": 250,
    "subscriptionPriceBDT": 400
  }
}
```

### 2. `createPaymentTransaction` (onCall)

Creates a payment transaction document from UddoktaPay response.

**Input:**
```json
{
  "type": "verification",
  "uddoktapayResponse": {
    "fullName": "John",
    "email": "...",
    "amount": "250.00",
    "invoiceId": "...",
    "transactionId": "...",
    "paymentMethod": "bkash",
    "status": "COMPLETED"
  }
}
```

**Behavior:**
- If status=COMPLETED → calls `processVerification`/`processSubscription`
- If status=PENDING → stores doc, does NOT process
- Returns `{ success: true, data: { paymentTransactionId, verified?, subscribed? } }`

### 3. `reVerifyPendingPayment` (onCall)

Re-verifies a pending payment by calling UddoktaPay's verify-payment API server-side.

**Input:**
```json
{
  "paymentTransactionId": "abc123..."
}
```

**Behavior:**
- Only works for PENDING payments owned by the authenticated user
- Calls UddoktaPay `POST /api/verify-payment` with `{ "invoice_id": "..." }`
- If UddoktaPay now returns COMPLETED → updates Firestore + processes verification/subscription
- Returns `{ success: true/false, data: { status, verified?, subscribed? } }`

### 4. `adminApprovePayment` (onCall)

Admin-only function to manually approve a pending payment.

**Input:**
```json
{
  "paymentTransactionId": "abc123..."
}
```

### 5. `uddoktapayWebhook` (HTTP — onRequest)

Receives POST from UddoktaPay when admin clicks "SEND WEBHOOK REQUEST" in dashboard.

**URL:** `https://uddoktapaywebhook-mik7xom3ca-el.a.run.app`

**Headers Required:**
- `RT-UDDOKTAPAY-API-KEY`: must match the configured API key

**Body (from UddoktaPay):**
```json
{
  "full_name": "...",
  "email": "...",
  "amount": "250.00",
  "fee": "0.00",
  "charged_amount": "250.00",
  "invoice_id": "...",
  "payment_method": "bkash",
  "sender_number": "01XXXXXXXXX",
  "transaction_id": "...",
  "date": "2025-01-15 12:00:00",
  "status": "COMPLETED",
  "metadata": {
    "payment_type": "verification",
    "uid": "..."
  }
}
```

**Behavior:**
- Validates API key header
- Finds payment by invoiceId
- If status changed to COMPLETED → auto-processes
- Creates audit log

### 6. `getPaymentHistory` (onCall)

Returns paginated payment history for the authenticated user.

### 7. `getAdminPaymentTransactions` (onCall)

Returns payment transactions for admin review panel.

---

## Flutter Layer

### Files

| File | Purpose |
|------|---------|
| `lib/features/verification/controllers/verification_controller.dart` | Main payment orchestration |
| `lib/features/verification/views/widgets/payment_result_dialog.dart` | Result dialog (success/pending/failed/cancelled) |
| `lib/data/repositories/payment_repository.dart` | Repository wrapping CF calls |
| `lib/core/services/cloud_functions_service.dart` | Generic CF callable service |

### Controller Methods

| Method | Purpose |
|--------|---------|
| `loadPaymentConfig()` | Fetches config from CF |
| `purchaseVerification()` | Starts verification payment flow |
| `purchaseSubscription()` | Starts subscription payment flow |
| `_processPayment()` | Core payment flow (SDK checkout + result handling) |
| `_handlePaymentSuccess()` | Sends COMPLETED payment to CF, shows success dialog |
| `_handlePaymentPending()` | Sends PENDING payment to CF, shows pending dialog with "Check Status" |
| `_checkPendingPaymentStatus()` | Calls reVerifyPendingPayment CF to poll UddoktaPay |
| `_handlePaymentFailure()` | Shows failed/cancelled dialog with retry |
| `loadPaymentHistory()` | Fetches paginated history |

### Payment Result Dialog

The `PaymentResultDialog` supports four states:

| State | Primary Button | Secondary Button |
|-------|---------------|-----------------|
| Success | "Done" | — |
| Pending | "Check Status" | "Close" |
| Failed | "Try Again" | "Close" |
| Cancelled | "Try Again" | "Close" |

---

## Local SDK Fork

The UddoktaPay SDK is forked locally at `packages/uddoktapay/` (v0.0.7).

### Key Files

| File | Purpose |
|------|---------|
| `lib/uddoktapay.dart` | Main SDK entry point |
| `lib/core/services/api_services.dart` | HTTP calls to UddoktaPay API |
| `lib/models/request_response.dart` | Response model with status parsing |
| `lib/models/credentials.dart` | SDK credentials (apiKey, panelURL, redirectURL, webhookUrl) |
| `lib/models/customer_model.dart` | Customer data model |
| `lib/views/payment_screen.dart` | WebView payment screen |

### Critical Fixes Applied

1. **Status Parsing** — `PENDING` from UddoktaPay is correctly mapped to `ResponseStatus.pending` (was incorrectly mapped to `canceled`)
2. **Redirect Detection** — Requires non-empty invoice_id + host match + NOT checkout page
3. **toJson Serialization** — `_statusToString()` converts enum to uppercase string
4. **URL Normalization** — Handles trailing slashes in panel URLs
5. **Webhook URL** — `webhook_url` is sent in checkout request body
6. **Metadata** — Real metadata (payment_type, uid) instead of dummy data

---

## Webhook (IPN) System

### How It Works

1. When creating a payment, the SDK sends `webhook_url` to UddoktaPay
2. UddoktaPay stores this URL for the payment
3. When admin approves a payment (e.g., SMS Data match), they can click "SEND WEBHOOK REQUEST"
4. UddoktaPay POSTs the payment data to our webhook URL
5. Our `uddoktapayWebhook` CF validates the API key, finds the payment, and auto-processes it

### Authentication

The webhook validates the `RT-UDDOKTAPAY-API-KEY` header matches the configured API key.

### CORS

The webhook handler includes CORS support for OPTIONS preflight requests.

---

## Re-Verify Mechanism

### Problem

When a user pays via SMS banking, UddoktaPay shows "Awaiting Review" status. Even though the transaction ID matches, the payment stays PENDING until:
1. UddoktaPay admin clicks "Approve" on the SMS Data entry, OR
2. Our webhook auto-processes it

The user sees a "Payment Pending" dialog and doesn't know when it completes.

### Solution

The `reVerifyPendingPayment` Cloud Function allows the app to poll UddoktaPay's verify-payment API:

```
User taps "Check Status" on pending dialog
    → Flutter calls reVerifyPendingPayment CF
    → CF reads payment doc from Firestore (gets invoiceId)
    → CF calls UddoktaPay POST /api/verify-payment
    → If COMPLETED → auto-processes + returns success
    → If PENDING → returns "still pending"
    → Flutter updates UI accordingly
```

### Three Ways Pending → Completed

1. **Webhook** — UddoktaPay admin sends webhook after approval
2. **Re-Verify** — User taps "Check Status" button
3. **Admin Approve** — SHIRAH admin manually approves via admin panel

---

## Status Handling

### UddoktaPay Status → Internal Status Mapping

| UddoktaPay Status | Internal Status | Action |
|-------------------|----------------|--------|
| `COMPLETED` | `COMPLETED` | Process verification/subscription |
| `PENDING` | `PENDING` | Store, wait for approval |
| (empty) | `PENDING` | Treated as pending |
| (other) | `FAILED` | Show error |

### Payment Transaction Document

```
payment_transactions/{id}
├── uid: string
├── type: "verification" | "subscription"
├── status: "COMPLETED" | "PENDING" | "FAILED" | "CANCELED"
├── invoiceId: string
├── transactionId: string
├── amount: string
├── fee: string
├── chargedAmount: string
├── paymentMethod: string
├── senderNumber: string
├── fullName: string
├── email: string
├── date: string
├── metadata: { payment_type, uid }
├── processedBy: "createPayment" | "adminApproval" | "webhook" | "re-verify"
├── processedAt: timestamp (when auto-processed)
├── createdAt: timestamp
└── updatedAt: timestamp
```

---

## Commission Distribution

When a payment is completed (via any path), `processVerification` or `processSubscription` is called:

1. Sets `user.status.verified = true` (or `subscription = "active"`)
2. Distributes commission to the user's upline chain
3. Commission rates and levels are configured in Firestore (`configurations/app_settings`)

This happens automatically regardless of which path completes the payment (direct, webhook, re-verify, or admin approve).

---

## Security

### Authentication
- All `onCall` CFs require Firebase Auth (`validateAuthenticated`)
- Users can only access their own payments
- Admin functions check `user.flags.isAdmin`

### Webhook
- Validates `RT-UDDOKTAPAY-API-KEY` header
- Rejects requests without valid API key
- Logs all webhook attempts in audit log

### Re-Verify
- Only the payment owner can re-verify their own payment
- Only PENDING payments can be re-verified
- Server-side API call (API key never exposed to client)

---

## Troubleshooting

### Payment stays PENDING

1. Check UddoktaPay dashboard → SMS Datas → is the transaction "Awaiting Review"?
2. If matched, click "Approve" → this should trigger webhook
3. Alternatively, user can tap "Check Status" in the app
4. If neither works, use SHIRAH admin panel to manually approve

### Webhook not firing

1. Verify `webhookURL` is set in Firestore: `configurations/app_settings.uddoktaPay.production.webhookURL`
2. Verify the CF is deployed: `https://uddoktapaywebhook-mik7xom3ca-el.a.run.app`
3. Check CF logs in Google Cloud Console
4. In UddoktaPay dashboard, click "SEND WEBHOOK REQUEST" button manually

### Config not loading

1. Check Firestore has `configurations/app_settings` document
2. Verify `uddoktaPay` field structure matches expected format
3. Check CF logs for `getPaymentConfig` errors

### SDK returns wrong status

The local SDK fork at `packages/uddoktapay/` has the fixed `_parseStatus()` method in `request_response.dart`. Ensure the app uses `path: packages/uddoktapay` dependency, not the pub.dev version.

---

## Deployed Cloud Functions

| Function | Type | URL/Callable |
|----------|------|-------------|
| `createPaymentTransaction` | onCall | Firebase Callable |
| `adminApprovePayment` | onCall | Firebase Callable |
| `getPaymentHistory` | onCall | Firebase Callable |
| `getAdminPaymentTransactions` | onCall | Firebase Callable |
| `getPaymentConfig` | onCall | Firebase Callable |
| `reVerifyPendingPayment` | onCall | Firebase Callable |
| `uddoktapayWebhook` | onRequest (HTTP) | `https://uddoktapaywebhook-mik7xom3ca-el.a.run.app` |

All functions run in **asia-south1** region on **Node.js 20** runtime.
