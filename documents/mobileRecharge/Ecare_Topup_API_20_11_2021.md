# 📱 SHIRAH – ECARE Mobile Recharge & Drive Offer System

> **Document Type:** ECARE API service documentation  
> **Version:** 1.0  
> **Last Updated:** February 16, 2026  
> **Synced With:** Cloud Functions (`functions/src/`) & Architecture Documents (`documents/`)  
> **Recharge History Store:** Firebase Firestore `mobile_recharge` collection under docId/refid → `mobile_recharge/{refid}`  
> **Purpose:** This document is a long-term reference note. You can open it after **1 year** and still clearly understand **why**, **how**, and **where** each part of the ECARE Service system works.  
> **Target Readers:** Developers, Tech Leads, Product Owners, Admins, Future Hires, AI Agents.

---

## 📋 Table of Contents

1. [System Overview](#1%EF%B8%8F⃣-system-overview)
2. [ECARE API Reference](#2%EF%B8%8F⃣-ecare-api-reference)
3. [Feature 1 — Mobile Recharge](#3%EF%B8%8F⃣-feature-1--mobile-recharge)
4. [Feature 2 — Drive Offer Pack Purchase](#4%EF%B8%8F⃣-feature-2--drive-offer-pack-purchase)
5. [Cashback & Reward System](#5%EF%B8%8F⃣-cashback--reward-system)
6. [Firestore Database Schema (New Collections)](#6%EF%B8%8F⃣-firestore-database-schema-new-collections)
7. [Cloud Functions Design](#7%EF%B8%8F⃣-cloud-functions-design)
8. [Data Flows (Step-by-Step)](#8%EF%B8%8F⃣-data-flows-step-by-step)
9. [Flutter Feature Implementation Guide](#9%EF%B8%8F⃣-flutter-feature-implementation-guide)
10. [Security, Compliance & Google Play Policy](#-security-compliance--google-play-policy)
11. [Error Handling & Edge Cases](#1%EF%B8%8F⃣1%EF%B8%8F⃣-error-handling--edge-cases)
12. [ECARE Provider Contact](#1%EF%B8%8F⃣2%EF%B8%8F⃣-ecare-provider-contact)

---

## 1️⃣ System Overview

### What Is This?

SHIRAH integrates with **ECARE Technology** (a third-party telecom recharge gateway) to offer two user-facing features:

| # | Feature | Description |
|---|---------|-------------|
| 1 | **Mobile Recharge** | Users recharge any Bangladeshi mobile number (GP, BL, Robi, Airtel, Teletalk) directly from their SHIRAH wallet. |
| 2 | **Drive Offer Pack Purchase** | Users browse and purchase operator-specific data/minute/bundle packs at listed prices. |

### Why?

- **User Value:** Recharge and buy packs without leaving the app. No need for bKash/Nagad/operator app.
- **Revenue:** ECARE provides shirah a **commission** on every transaction. shirah passes a portion as **cashback** to incentivize usage.
- **Retention:** Wallet balance use → sticky users → more ad views → more reward points → ecosystem loop.

### How It Works (High-Level)

```
┌──────────────────────┐
│   SHIRAH Flutter App  │
│   (User Interface)    │
└──────────┬───────────┘
           │ 1. User requests recharge / offer purchase
           ▼
┌──────────────────────┐
│ Firebase Cloud        │
│ Functions (Backend)   │
│                       │
│ ├─ Validate user      │
│ ├─ Check wallet       │
│ ├─ Debit wallet       │
│ ├─ Call ECARE API     │
│ ├─ Store in Firestore │
│ ├─ Credit cashback    │
│ └─ Audit log          │
└──────────┬───────────┘
           │ 2. HTTP GET request
           ▼
┌──────────────────────┐
│  ECARE Technology     │
│  Topup API Server     │
│  (Third-Party)        │
└──────────────────────┘
```

### Architecture Fit

```
Flutter App (View) → Controller → Cloud Function (callable)
Cloud Function     → ECARE API (HTTP GET)
Cloud Function     → Firestore (write history, cashback, audit)
```

---

## 2️⃣ ECARE API Reference

### Base URL

```
http://118.179.129.98/myportal/api/rechargeapi/recharge_api_thirdparty.php
```

> ⚠️ **Note:** This is an HTTP (not HTTPS) endpoint. All API calls MUST happen server-side in Cloud Functions only. Never call from Flutter client.

### Authentication

Every API request requires two query parameters for authentication:

| Parameter | Description |
|-----------|-------------|
| `access_id` | API username assigned by ECARE |
| `access_pass` | API password assigned by ECARE |

> 🔐 **CRITICAL:** Credentials are stored as Firebase environment secrets. Never hardcode in client code, never commit to Git, never log in production.

### Common Parameters (All Endpoints)

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `access_id` | String | ✅ | API username |
| `access_pass` | String | ✅ | API password |
| `service` | String | ✅ | Service code identifying the endpoint |

### HTTP Method

All ECARE API requests use **HTTP GET** with query string parameters.

### General Error Responses (All Endpoints)

These error codes can be returned by **any** endpoint before processing:

| STATUS | MESSAGE | Meaning |
|--------|---------|---------|
| `FAILED` | `Login Failed, Invalid Credential` | Wrong `access_id` or `access_pass` |
| `MAINTENANCE` | `Server Maintenance Mode Running, Try After Sometime` | ECARE server is under maintenance |
| `INVALID` | `SERVICE` | Invalid `service` parameter value |

---

### 2.1) Mobile Recharge API

**Service Code:** `MRC`

#### Request Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `service` | String | ✅ | Must be `MRC` |
| `operator` | String | ✅ | Operator code (see Operator Code Table) |
| `number_type` | String | ✅ | Number type code (see Number Type Table) |
| `number` | String | ✅ | 11-digit Bangladeshi MSISDN (e.g., `01700000000`). No country code prefix. |
| `amount` | String | ✅ | Recharge amount in BDT (integer, no decimals) |
| `refid` | String | ✅ | **Unique reference ID** per request. Used to track and check status later. Duplicate `refid` will be rejected. |

#### Example Request

```
GET http://118.179.129.98/myportal/api/rechargeapi/recharge_api_thirdparty.php
  ?access_id={ACCESS_ID}
  &access_pass={ACCESS_PASS}
  &service=MRC
  &operator=6
  &number_type=1
  &number=01602475999
  &amount=20
  &refid=SHR_1708089600000_a1b2c3
```

#### Success Response (Verified)

```json
{
    "STATUS": "OK",
    "RECHARGE_STATUS": "RECEIVED",
    "OPERATOR": "6",
    "NUMBER": "01602475999",
    "AMOUNT": "20",
    "TRXID": "E160226MRC15602022",
    "MESSAGE": "Your Mobile Recharge Request Received."
}
```

#### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `STATUS` | String | `OK` = accepted, `FAILED` = rejected |
| `RECHARGE_STATUS` | String | Detailed recharge outcome |
| `OPERATOR` | String | Operator code echoed back |
| `NUMBER` | String | Phone number echoed back |
| `AMOUNT` | String | Amount echoed back |
| `TRXID` | String | ECARE transaction ID (store this for reference) |
| `MESSAGE` | String | Human-readable message |

#### Response Status Mapping

| STATUS | RECHARGE_STATUS | MESSAGE | Action |
|--------|----------------|---------|--------|
| `OK` | `RECEIVED` | `Your Mobile Recharge Request Received.` | ✅ Accepted — poll status until terminal |
| `FAILED` | `DUPLICATE` | `Duplicate Reference or Duplicate Recharge Request` | ❌ Same `refid` used before — generate a new one |
| `FAILED` | `LOWBALANCE` | `Insufficient Wallet Balance` | ❌ ECARE account balance is low — alert admin |
| `FAILED` | `FAILED` | `Recharge Request Failed.` | ❌ Generic failure — log and retry with new `refid` if appropriate |
| `FAILED` | `REJECT` | `Sorry! Invalid Credentials.` | ❌ Auth failure — check secrets config |

> **Important:** `RECEIVED` is NOT a success. It means ECARE accepted the request. You MUST poll `MRCSTATUS` to confirm `SUCCESS`.

---

### 2.2) Recharge Status Check API

**Service Code:** `MRCSTATUS`

#### Request Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `service` | String | ✅ | Must be `MRCSTATUS` |
| `refid` | String | ✅ | The same unique reference ID used in the original recharge request |

#### Example Request

```
GET http://118.179.129.98/myportal/api/rechargeapi/recharge_api_thirdparty.php
  ?access_id={ACCESS_ID}
  &access_pass={ACCESS_PASS}
  &service=MRCSTATUS
  &refid=SHR_1708089600000_a1b2c3
```

#### Success Response (Verified)

```json
{
    "STATUS": "OK",
    "RECHARGE_STATUS": "SUCCESS",
    "RECHARGE_TRXID": "R260216.1635.360081",
    "MESSAGE": "200: Recharge Tk20 to 01602475999 SUCCESS. TrxID: E160226MRC15602022. C/B Tk93.55. @ECARE"
}
```

#### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `STATUS` | String | `OK` = valid response, `FAILED` = error |
| `RECHARGE_STATUS` | String | Terminal or non-terminal status |
| `RECHARGE_TRXID` | String | Operator-level transaction ID (different from ECARE TRXID) |
| `MESSAGE` | String | Detail message (may contain amount, number, TrxID, balance info) |

#### Response Status Mapping

| STATUS | RECHARGE_STATUS | Meaning | Terminal? |
|--------|----------------|---------|-----------|
| `OK` | `SUCCESS` | Recharge completed successfully | ✅ Yes — terminal success |
| `OK` | `FAILED` | Recharge failed at operator level | ✅ Yes — terminal failure |
| `OK` | `PENDING` | Request is queued, not yet processed | ❌ No — keep polling |
| `OK` | `PROCESSING` | Request is being processed | ❌ No — keep polling |
| `FAILED` | `INVALIDREF` | `refid` not found in ECARE system | ✅ Yes — invalid reference |

#### Polling Strategy

```
Poll Interval:   5s → 10s → 15s → 30s → 60s (exponential backoff)
Max Polls:       10 attempts
Max Wait Time:   ~5 minutes
If still PENDING/PROCESSING after max polls → mark as "pending_verification" and alert admin
```

---

### 2.3) Balance Check API

**Service Code:** `BLCK`

#### Request Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `service` | String | ✅ | Must be `BLCK` |

> No additional parameters needed beyond auth credentials.

#### Example Request

```
GET http://118.179.129.98/myportal/api/rechargeapi/recharge_api_thirdparty.php
  ?access_id={ACCESS_ID}
  &access_pass={ACCESS_PASS}
  &service=BLCK
```

#### Success Response (Verified)

```json
{
    "STATUS": "OK",
    "MAIN_BALANCE": "113.55",
    "STOCK_BALANCE": "30.00",
    "COMMISSION_TYPE": "Prepaid",
    "COMMISSION_RATE": "2.70",
    "MESSAGE": "Balance Equerry Success"
}
```

#### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `STATUS` | String | `OK` = success |
| `MAIN_BALANCE` | String | Available balance in ECARE merchant wallet (BDT). This is the money used for recharges. |
| `STOCK_BALANCE` | String | Reserved/stock balance (BDT) |
| `COMMISSION_TYPE` | String | Type of commission structure (e.g., `Prepaid`) |
| `COMMISSION_RATE` | String | Commission percentage earned per recharge (e.g., `2.70` = 2.70%) |
| `MESSAGE` | String | `Balance Equerry Success` on success |

> **Admin Use Only:** This endpoint is for admin dashboard to monitor ECARE account balance. Never expose to regular users.

---

### 2.4) Drive Pack Offer List API

**Service Code:** `OFFERPACK`

#### Request Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `service` | String | ✅ | Must be `OFFERPACK` |

> No additional parameters needed beyond auth credentials.

#### Example Request

```
GET http://118.179.129.98/myportal/api/rechargeapi/recharge_api_thirdparty.php
  ?access_id={ACCESS_ID}
  &access_pass={ACCESS_PASS}
  &service=OFFERPACK
```

#### Response Structure

The response returns a JSON object with operator keys (`GP`, `BL`, `RB`, `AR`, `TL`) each containing an array of available offer packs:

```json
{
    "STATUS": "OK",
    "GP": [ ... ],
    "BL": [ ... ],
    "RB": [ ... ],
    "AR": [ ... ],
    "TL": [ ... ],
    "MESSAGE": "Operator Wise Recharge Offer Details"
}
```

#### Single Offer Pack Object

```json
{
    "_operator": "RB",
    "_number_type": "1",
    "_offer_type": "MN",
    "_minute_pack": "100 Min",
    "_internet_pack": "-",
    "_sms_pack": "-",
    "_callrate_pack": "-",
    "_validity": "30 Days",
    "_amount": "116",
    "_commission_amount": "2.00",
    "_status": "A",
    "_offer_details": ""
}
```

#### Offer Pack Field Reference

| Field | Type | Description |
|-------|------|-------------|
| `_operator` | String | Operator short code |
| `_number_type` | String | Target number type |
| `_offer_type` | String | Pack category |
| `_minute_pack` | String | Minutes included (e.g., `100 Min`). `-` if not applicable. |
| `_internet_pack` | String | Data included (e.g., `50 GB`). `-` if not applicable. May contain variants like `50/70 GB`. |
| `_sms_pack` | String | SMS included. `-` if not applicable. |
| `_callrate_pack` | String | Special call rate. `-` if not applicable. |
| `_validity` | String | Pack validity period (e.g., `30 Days`, `7 Days`, `365 Days`) |
| `_amount` | String | Price in BDT (integer string) — this is what the user pays |
| `_commission_amount` | String | Commission earned per sale (BDT) — this is what the user gets as cashback |
| `_status` | String | `A` = Active (available for purchase) |
| `_offer_details` | String | Additional details (usually empty) |

---

### Reference Tables (ECARE Codes)

#### Operator Codes (Recharge API)

| Operator | Code (Recharge) | Code (Offer Response) | Notes |
|----------|----------------|-----------------------|-------|
| Grameenphone | `3` or `7` | `GP` | Use both `7` and `3` for standard prepaid recharge |
| Banglalink | `4` or `9` | `BL` | Use both `4` and `9` for standard prepaid recharge |
| Robi | `8` | `RB` | |
| Airtel | `6` | `AR` | |
| Teletalk | `5` | `TL` | |

> **Mapping Note:** The recharge API uses numeric codes, but the offer list API returns string codes. Cloud Functions must maintain a mapping between these.

#### Number Type Codes

| Code | Type | Description |
|------|------|-------------|
| `1` | Prepaid | Standard prepaid number |
| `2` | Postpaid | Postpaid/bill pay number |
| `3` | Skitto | Grameenphone's sub-brand |
| `4` | PowerLoad / G.Store / Amar Offer | Special recharge types |

#### Offer Type Codes (Drive Pack Only)

| Code | Type | Description |
|------|------|-------------|
| `IN` | Internet | Data-only pack |
| `BD` | Bundle | Combo pack (data + minutes + SMS) |
| `MN` | Minutes | Voice minutes-only pack |

---

## 3️⃣ Feature 1 — Mobile Recharge

### What Users See

1. User opens "Mobile Recharge" screen.
2. Enters/selects: **phone number**, **operator**, **number type**, **amount**.
3. The system automatically checks: does a matching **Drive Offer Pack** exist for this exact amount and operator?
   - If **YES (Offer Match Found)** → ⚠️ **CRITICAL BEHAVIOR:**
     - The system will **NOT** perform a simple balance recharge.
     - Instead, it will **activate the matching Drive Offer Pack** on the phone number.
     - Show a **clear warning** to the user: _"⚠️ A drive offer pack is available at ৳{amount}. If you confirm, the {pack_details} offer will be activated on {phone_number}. This is NOT a balance recharge. You'll earn ৳{commission} cashback."_
     - User must **explicitly understand** they're getting a pack, not plain balance.
     - Option to **switch to plain recharge** should be disabled for exact match amounts (to avoid confusion).
   - If **NO (No Match)** → Continue with standard recharge (1.5% cashback).
     - System will recharge the phone number balance directly.
     - Show confirmation: _"Recharge ৳{amount} balance to {phone_number}. You'll earn ৳{cashback} (1.5%) cashback."_
4. User confirms → wallet is debited → recharge/offer is processed → history is saved.

### ⚠️ Important: Recharge vs Drive Offer

**Both features use the same ECARE API endpoints:**

| Feature | ECARE API Used | What Happens |
|---------|---------------|-------------|
| **Plain Recharge** | `MRC` + `MRCSTATUS` | Phone number balance is topped up (e.g., ৳100 → ৳100 balance added) |
| **Drive Offer Purchase** | `MRC` + `MRCSTATUS` | Operator-specific pack is activated (e.g., ৳116 → 100 Min + validity pack activated, **NOT ৳116 balance**) |

**Key Difference:**
- Plain recharge: User gets **balance** (taka) on their phone.
- Drive offer: User gets a **pack** (data/minutes/bundle) with specific validity. **No balance is added.**

**When Amount Matches an Offer:**
- If user enters ৳116 and a drive offer exists for ৳116 → System will activate the pack, not recharge ৳116 balance.
- User MUST be warned clearly before confirming.

### Cashback Rules

| Type | Cashback Calculation | Example |
|------|---------------------|----------|
| **Plain Recharge** | `amount × 1.5%` | Recharge ৳100 → Cashback ৳1.50 |
| **Drive Offer Purchase** | `pack's _commission_amount` | Buy ৳116 pack → Cashback ৳2.00 (from pack data) |

### refid Format

```
Format: SHR_{timestamp_ms}_{random_6_chars}
Example: SHR_1708089600000_a1b2c3
Purpose: Unique per request, traceable to shirah, used for ECARE status polling
```

### Amount Validation Rules

⚠️ **All recharge amounts MUST be round figures (ending in 0).**

| Rule | Value | Notes |
|------|-------|-------|
| Minimum amount | ৳20 | Lowest acceptable amount |
| Amount format | **Round figure only** | Must end in 0 (e.g., 20, 30, 50, 100, 120, 520, 990) |
| Invalid examples | ~~৳15~~, ~~৳22~~, ~~৳35~~, ~~৳119~~ | Last digit is not 0 → rejected |
| Valid examples | ✅ ৳20, ৳30, ৳50, ৳100, ৳120, ৳520, ৳990, ৳5000 | All end in 0 |
| Maximum amount | ৳5,000 | Highest acceptable amount |

**Validation Logic (Pseudo-code):**

```typescript
function isValidRechargeAmount(amount: number): boolean {
  if (amount < 20) return false;             // Below minimum
  if (amount > 5000) return false;           // Above maximum
  if (amount % 10 !== 0) return false;       // Not a round figure (doesn't end in 0)
  return true;
}

// Examples:
isValidRechargeAmount(20)   → true   ✅
isValidRechargeAmount(30)   → true   ✅
isValidRechargeAmount(119)  → false  ❌ (not round figure)
isValidRechargeAmount(120)  → true   ✅
isValidRechargeAmount(15)   → false  ❌ (below minimum)
isValidRechargeAmount(5010) → false  ❌ (above maximum)
```

### Business Rules

| Rule | Value |
|------|-------|
| Minimum recharge amount | ৳20 |
| Maximum recharge amount | ৳5,000 |
| Amount format | **Must be round figure (ending in 0)** |
| Payment source | `users/{uid}/wallet/balanceBDT` only |
| Wallet must be unlocked | `users/{uid}/wallet/locked == false` |
| Account must be active | `users/{uid}/status/accountState == "active"` |
| Account must be verified | `users/{uid}/status/verified == true` |
| Max recharges per day | 20 (anti-abuse) |
| Cashback percentage (plain recharge) | 1.5% of recharge amount |
| Cashback amount (drive offer) | Exact `_commission_amount` from pack |
| Cashback credited on | Terminal `SUCCESS` from ECARE only |

---

## 4️⃣ Feature 2 — Drive Offer Pack Purchase

### What Users See

1. User opens "Drive Offers" screen.
2. **Search & Filter:** User can filter by:
   - **Operator** (GP, BL, Robi, Airtel, Teletalk)
   - **Offer Type** (Internet, Bundle, Minutes)
   - **Amount range** (e.g., ৳100–৳500)
3. User selects an offer pack → views pack details (minutes, data, validity, price, cashback).
4. User enters the **destination phone number** where the pack should be activated.
5. **⚠️ Important Warning Shown:**
   - _"You are purchasing a {pack_details} pack. This will activate the offer on {phone_number}. This is NOT a balance recharge. The pack will be valid for {validity}. You'll earn ৳{commission} cashback."_
6. User confirms → wallet is debited → pack purchase is processed → history is saved.

### Cashback Rule

```
Drive Offer Pack Cashback = pack's "_commission_amount" field value
Example: Pack costs ৳116, _commission_amount = "2.00" → Cashback = ৳2.00 added to users/{uid}/wallet/balanceBDT
```

> **Why different from recharge?** ECARE provides a fixed commission per pack. We pass this full commission to the user as cashback. This is more transparent and competitive.

### How Drive Offer Purchase Works (via ECARE)

Drive offer packs are purchased **through the same Recharge API** (`service=MRC`). The pack is activated by sending the exact `_amount` value.

**⚠️ IMPORTANT: When you send `MRC` with an amount that matches a drive offer:**
- ECARE does NOT recharge the balance.
- ECARE activates the operator-specific pack on the number.
- The user receives the pack benefits (data/minutes/validity), NOT balance.

```
operator    = mapped from _operator (GP→7, BL→4, RB→8, AR→6, TL→5)
number_type = _number_type from the offer pack (usually "1" for Prepaid)
amount      = _amount from the offer pack (exact match required)
number      = user-entered phone number
```

**Example:**

```
Offer Pack: { _operator: "RB", _amount: "116", _minute_pack: "100 Min", _validity: "30 Days" }

API Call: MRC?operator=8&number_type=1&number=01712345678&amount=116&refid=SHR_...

Result: The phone number 01712345678 gets a 100-minute pack valid for 30 days.
        ❌ The phone does NOT get ৳116 balance.
```

### Business Rules

| Rule | Value |
|------|-------|
| Pack list cache | Cloud Functions cache the OFFERPACK response for 1 hour |
| Amount validation | **Drive offer amounts are pre-defined by ECARE** — no round figure restriction |
| Payment source | `users/{uid}/wallet/balanceBDT` only |
| Wallet must be unlocked | `users/{uid}/wallet/locked == false` |
| Account must be active | `users/{uid}/status/accountState == "active"` |
| Account must be verified | `users/{uid}/status/verified == true` |
| Max purchases per day | 10 (anti-abuse) |
| Cashback amount | Exact `_commission_amount` from the pack |
| Cashback credited on | Terminal `SUCCESS` from ECARE only |

> **Note:** Drive offer pack amounts (e.g., ৳116, ৳119, ৳233) do NOT need to be round figures because they are pre-defined by the operator/ECARE. The round figure rule only applies to user-entered recharge amounts.

---

## 5️⃣ Cashback & Reward System

### Cashback Summary

| Feature | Cashback Source | Calculation | Credited To |
|---------|----------------|-------------|-------------|
| Mobile Recharge | shirah policy | `amount × 1.5%` | `users/{uid}/wallet/balanceBDT` (increment) |
| Drive Offer Purchase | ECARE commission | `_commission_amount` value | `users/{uid}/wallet/balanceBDT` (increment) |

### Cashback Lifecycle

```
1. User initiates recharge/purchase
2. Cloud Function debits user wallet (amount deducted)
3. Cloud Function calls ECARE API
4. ECARE returns RECEIVED → function polls MRCSTATUS
5. MRCSTATUS returns SUCCESS
6. Cloud Function increments wallet.balanceBDT by cashback amount
7. Cloud Function creates wallet_transactions document (cashback credit)
8. Cloud Function creates audit_logs document
9. User sees cashback in their wallet history
```

### When Cashback is NOT Given

- ECARE returns `FAILED` → no cashback, wallet refunded
- ECARE returns `PENDING`/`PROCESSING` beyond max poll → no cashback yet, admin investigates
- User account is suspended/banned → no transactions allowed
- User wallet is locked → no transactions allowed

---

## 6️⃣ Firestore Database Schema (New Collections)

### New Collection: `mobile_recharge`

> **One document per recharge or offer purchase.** Document ID = `refid` (the unique reference ID sent to ECARE).  
> Immutable once terminal status reached. Only Cloud Functions write.

```
mobile_recharge (Collection)
└── {refid} (Document)                   # Same as refid sent to ECARE (e.g., "SHR_1708089600000_a1b2c3")
    │
    ├── refid : String                   # Same as document ID (unique reference)
    ├── uid : String                     # Firebase Auth UID of the user who initiated
    │
    ├── type : String                    # Transaction type
    │                                    # ENUM: "recharge" | "drive_offer"
    │
    ├── phone : String                   # Destination phone number (11 digits, e.g., "01602475999")
    ├── operator : String                # Operator code sent to ECARE (e.g., "7" for GP)
    ├── operatorName : String            # Human-readable operator name (e.g., "Grameenphone")
    ├── numberType : String              # Number type code (e.g., "1")
    ├── numberTypeName : String          # Human-readable (e.g., "Prepaid")
    ├── amount : Number                  # Amount in BDT (what user paid)
    │
    ├── offer : Map | null               # Drive offer pack details (null for standard recharge)
    │   ├── offerType : String           # "IN" | "BD" | "MN"
    │   ├── offerTypeName : String       # "Internet" | "Bundle" | "Minutes"
    │   ├── minutePack : String          # e.g., "100 Min" or "-"
    │   ├── internetPack : String        # e.g., "50 GB" or "-"
    │   ├── smsPack : String             # e.g., "-"
    │   ├── callratePack : String        # e.g., "-"
    │   ├── validity : String            # e.g., "30 Days"
    │   └── commissionAmount : Number    # ECARE commission (BDT), e.g., 2.00
    │
    ├── cashback : Map                   # Cashback details
    │   ├── amount : Number              # Cashback credited (BDT)
    │   ├── percentage : Number | null   # For recharge: 1.5 (%), for drive offer: null
    │   ├── source : String              # "recharge_cashback" | "drive_offer_cashback"
    │   └── credited : Boolean           # Whether cashback has been credited to wallet
    │
    ├── ecare : Map                      # Raw ECARE API data
    │   ├── trxId : String | null        # ECARE transaction ID from recharge response
    │   ├── rechargeTrxId : String | null # Operator transaction ID from status check
    │   ├── lastMessage : String         # Last message from ECARE API
    │   └── pollCount : Number           # Number of status check polls made
    │
    ├── wallet : Map                     # Wallet snapshot at time of transaction
    │   ├── balanceBefore : Number       # Wallet balance before debit
    │   ├── balanceAfterDebit : Number   # Wallet balance after debit (before cashback)
    │   └── balanceAfterCashback : Number | null  # Wallet balance after cashback (null if not yet credited)
    │
    ├── status : String                  # Overall transaction status (shirah-level)
    │                                    # ENUM: "initiated"           → wallet debited, ECARE not yet called
    │                                    #       "submitted"           → ECARE returned RECEIVED
    │                                    #       "processing"          → ECARE status is PENDING/PROCESSING
    │                                    #       "success"             → ECARE confirmed SUCCESS + cashback credited
    │                                    #       "failed"              → ECARE confirmed FAILED
    │                                    #       "refunded"            → ECARE failed + wallet refunded
    │                                    #       "pending_verification"→ Max polls reached, needs admin review
    │
    ├── ecareStatus : String | null      # Raw ECARE RECHARGE_STATUS (e.g., "SUCCESS", "FAILED", "PENDING")
    │
    ├── error : Map | null               # Error details (null if no error)
    │   ├── code : String                # Error code (e.g., "LOWBALANCE", "DUPLICATE")
    │   └── message : String             # Error message
    │
    ├── walletTransactionId : String | null   # Reference to wallet_transactions doc for the debit
    ├── cashbackTransactionId : String | null # Reference to wallet_transactions doc for the cashback credit
    ├── auditLogId : String | null            # Reference to audit_logs doc
    │
    ├── createdAt : Timestamp            # When user initiated the transaction
    ├── submittedAt : Timestamp | null   # When ECARE accepted (RECEIVED)
    ├── completedAt : Timestamp | null   # When terminal status reached (SUCCESS/FAILED)
    └── updatedAt : Timestamp            # Last document update
```

### New Collection: `drive_offer_cache`

> **Cached ECARE offer pack list.** Single document updated periodically by a scheduled function or on-demand.  
> Flutter reads via Cloud Function (never directly).

```
drive_offer_cache (Collection)
└── latest (Document)                    # Fixed document ID
    ├── offers : Array<Map>              # Flattened list of all offers (all operators combined)
    │   └── [n] : Map                    # Single offer
    │       ├── operator : String        # "GP" | "BL" | "RB" | "AR" | "TL"
    │       ├── operatorName : String    # "Grameenphone" | "Banglalink" | "Robi" | "Airtel" | "Teletalk"
    │       ├── numberType : String      # "1" (Prepaid) | "2" (Postpaid)
    │       ├── offerType : String       # "IN" | "BD" | "MN"
    │       ├── offerTypeName : String   # "Internet" | "Bundle" | "Minutes"
    │       ├── minutePack : String      # e.g., "100 Min" or "-"
    │       ├── internetPack : String    # e.g., "50 GB" or "-"
    │       ├── smsPack : String         # e.g., "-"
    │       ├── callratePack : String    # e.g., "-"
    │       ├── validity : String        # e.g., "30 Days"
    │       ├── amount : Number          # Price in BDT
    │       ├── commissionAmount : Number # Commission (BDT)
    │       └── status : String          # "A" = Active
    │
    ├── operatorCounts : Map             # Quick stats
    │   ├── GP : Number                  # Total GP offers
    │   ├── BL : Number                  # Total BL offers
    │   ├── RB : Number                  # Total RB offers
    │   ├── AR : Number                  # Total AR offers
    │   └── TL : Number                  # Total TL offers
    │
    ├── totalOffers : Number             # Grand total offers
    ├── fetchedAt : Timestamp            # When ECARE was last polled
    └── expiresAt : Timestamp            # Cache expiry time (fetchedAt + 1 hour)
```

### Existing Collections — New Entries

#### `wallet_transactions` — New Source Types

Two new `source` enum values added:

| Source | Type | Description |
|--------|------|-------------|
| `recharge_debit` | `debit` | Wallet debit for mobile recharge or drive offer purchase |
| `recharge_cashback` | `credit` | Cashback credited after successful recharge |
| `drive_offer_cashback` | `credit` | Cashback credited after successful drive offer purchase |
| `recharge_refund` | `credit` | Wallet refund when recharge fails at ECARE |

#### `audit_logs` — New Action Types

| Action | Description |
|--------|-------------|
| `recharge.initiate` | User initiated a mobile recharge |
| `recharge.success` | Recharge completed successfully |
| `recharge.failed` | Recharge failed |
| `recharge.refund` | Wallet refunded after failed recharge |
| `drive_offer.initiate` | User initiated a drive offer purchase |
| `drive_offer.success` | Drive offer purchase completed successfully |
| `drive_offer.failed` | Drive offer purchase failed |
| `drive_offer.refund` | Wallet refunded after failed drive offer purchase |

---

## 7️⃣ Cloud Functions Design

### New Callable Functions

| Function Name | Role Required | Description |
|---------------|--------------|-------------|
| `initiateRecharge` | Verified User | Initiate a mobile recharge (standard or drive offer) |
| `getRechargeHistory` | Authenticated User | Fetch user's recharge history (paginated) |
| `getDriveOffers` | Authenticated User | Get cached drive offer list (with filters) |
| `searchDriveOffers` | Authenticated User | Search offers by operator, type, amount |
| `getEcareBalance` | Admin | Check ECARE merchant account balance |
| `refreshDriveOfferCache` | Admin / Scheduled | Force-refresh the cached drive offer list |
| `adminRechargeStatus` | Admin | Manually check ECARE status for a pending transaction |

### Function: `initiateRecharge`

**Input Parameters:**

```typescript
{
  phone: string;        // 11-digit Bangladeshi number (e.g., "01602475999")
  operator: string;     // Operator code for ECARE API (e.g., "7" for GP)
  numberType: string;   // "1" (Prepaid) | "2" (Postpaid) | "3" (Skitto) | "4" (PowerLoad)
  amount: number;       // Recharge amount in BDT
  type: string;         // "recharge" | "drive_offer"
  offerDetails?: {      // Required only when type == "drive_offer"
    offerType: string;        // "IN" | "BD" | "MN"
    minutePack: string;
    internetPack: string;
    smsPack: string;
    callratePack: string;
    validity: string;
    commissionAmount: number;
  }
}
```

**Processing Steps (Pseudo-code):**

```
1. AUTH: Verify caller is authenticated
2. VALIDATE:
   a. Phone number is valid 11-digit Bangladeshi MSISDN
   b. Operator code is valid
   c. Amount is within min/max range
   d. If drive_offer → validate offerDetails present and valid
3. USER CHECK:
   a. User exists and accountState == "active"
   b. User is verified
   c. Wallet is NOT locked
   d. Daily recharge limit not exceeded
4. WALLET CHECK:
   a. balanceBDT >= amount
5. GENERATE refid:
   a. Format: "SHR_{timestamp_ms}_{random_6}"
6. DEBIT WALLET (Firestore transaction):
   a. Decrement users/{uid}/wallet/balanceBDT by amount
   b. Create wallet_transactions doc (debit, source: "recharge_debit")
   c. Create mobile_recharge/{refid} doc (status: "initiated")
7. CALL ECARE RECHARGE API:
   a. HTTP GET with all parameters
   b. If RECEIVED → update mobile_recharge status to "submitted"
   c. If FAILED → update status to "failed", REFUND wallet, create refund transaction
8. POLL STATUS (if RECEIVED):
   a. Wait 5s → call MRCSTATUS
   b. If SUCCESS → credit cashback, update status to "success"
   c. If FAILED → refund wallet, update status to "refunded"
   d. If PENDING/PROCESSING → continue polling (max 10 attempts)
   e. If max polls exceeded → mark "pending_verification", alert admin
9. AUDIT LOG:
   a. Create audit_logs doc with full context
10. RETURN result to Flutter
```

### Function: `getDriveOffers`

**Input Parameters:**

```typescript
{
  operator?: string;   // Filter by operator ("GP" | "BL" | "RB" | "AR" | "TL")
  offerType?: string;  // Filter by type ("IN" | "BD" | "MN")
  minAmount?: number;  // Minimum price filter
  maxAmount?: number;  // Maximum price filter
}
```

**Processing Steps:**

```
1. AUTH: Verify caller is authenticated
2. READ drive_offer_cache/latest
3. If cache expired or not found → call ECARE OFFERPACK API → update cache
4. FILTER offers based on input parameters
5. SORT by amount ascending (cheapest first)
6. RETURN filtered & sorted offers
```

### Function: `searchDriveOffers`

**Input Parameters:**

```typescript
{
  amount: number;      // Exact amount to search
  operator: string;    // Operator code ("GP" | "BL" | "RB" | "AR" | "TL")
  offerType?: string;  // Optional type filter ("IN" | "BD" | "MN")
}
```

**Processing Steps:**

```
1. AUTH: Verify caller is authenticated
2. READ cached offers
3. FIND exact match by amount + operator (+ optional offerType)
4. RETURN matching offers (may be 0 or multiple)
```

> **Smart Recharge Integration:** When a user enters a recharge amount, Flutter calls `searchDriveOffers` with that amount and operator. If results are found, show a suggestion: _"A drive offer pack is available at ৳{amount}! Get ৳{commission} cashback."_

---

## 8️⃣ Data Flows (Step-by-Step)

### Flow A: Successful Mobile Recharge

```
User taps "Recharge ৳100 to 01712345678 (GP Prepaid)"
    │
    ├── 1. Cloud Function: initiateRecharge called
    │
    ├── 2. Validation passes (user active, verified, wallet unlocked, balance >= 100)
    │
    ├── 3. Generate refid: "SHR_1708089600000_a1b2c3"
    │
    ├── 4. Firestore Transaction (atomic):
    │   ├── users/{uid}/wallet/balanceBDT: 500 → 400 (debit ৳100)
    │   ├── wallet_transactions/{autoId}: type="debit", source="recharge_debit", amount=100,
    │   │     balanceBefore=500, balanceAfter=400, reference="SHR_1708089600000_a1b2c3"
    │   └── mobile_recharge/SHR_1708089600000_a1b2c3: status="initiated", amount=100, ...
    │
    ├── 5. Call ECARE: MRC?operator=7&number_type=1&number=01712345678&amount=100&refid=SHR_...
    │   └── Response: { STATUS: "OK", RECHARGE_STATUS: "RECEIVED", TRXID: "E160226..." }
    │
    ├── 6. Update mobile_recharge: status="submitted", ecare.trxId="E160226..."
    │
    ├── 7. Poll MRCSTATUS (attempt 1, backoff 5s):
    │   └── Response: { STATUS: "OK", RECHARGE_STATUS: "SUCCESS", RECHARGE_TRXID: "R260216..." }
    │
    ├── 8. Cashback (Firestore Transaction):
    │   ├── Cashback = 100 × 1.5% = ৳1.50
    │   ├── users/{uid}/wallet/balanceBDT: 400 → 401.50 (credit ৳1.50)
    │   ├── wallet_transactions/{autoId}: type="credit", source="recharge_cashback", amount=1.50,
    │   │     balanceBefore=400, balanceAfter=401.50, reference="SHR_1708089600000_a1b2c3"
    │   └── mobile_recharge: status="success", cashback.credited=true, cashback.amount=1.50
    │
    ├── 9. audit_logs/{autoId}: action="recharge.success", targetUid=uid, metadata={refid, amount, phone, ...}
    │
    └── 10. Return to Flutter: { success: true, status: "success", cashback: 1.50 }
```

### Flow B: Successful Drive Offer Purchase

```
User selects "GP Bundle: 500 Min + 22/27 GB, 30 Days, ৳699, Cashback ৳19.00"
User enters phone: 01712345678
    │
    ├── 1. Cloud Function: initiateRecharge called (type="drive_offer")
    │
    ├── 2. Validation passes
    │
    ├── 3. Generate refid: "SHR_1708089610000_d4e5f6"
    │
    ├── 4. Firestore Transaction (atomic):
    │   ├── users/{uid}/wallet/balanceBDT: 1000 → 301 (debit ৳699)
    │   ├── wallet_transactions/{autoId}: type="debit", source="recharge_debit", amount=699,
    │   │     balanceBefore=1000, balanceAfter=301
    │   └── mobile_recharge/SHR_...: status="initiated", type="drive_offer", amount=699,
    │         offer={offerType:"BD", minutePack:"500 Min", internetPack:"22/27 GB", ...}
    │
    ├── 5. Call ECARE: MRC?operator=7&number_type=1&number=01712345678&amount=699&refid=SHR_...
    │
    ├── 6–7. Same RECEIVED → poll → SUCCESS flow
    │
    ├── 8. Cashback (Firestore Transaction):
    │   ├── Cashback = ৳19.00 (from offer's _commission_amount)
    │   ├── users/{uid}/wallet/balanceBDT: 301 → 320 (credit ৳19.00)
    │   ├── wallet_transactions/{autoId}: type="credit", source="drive_offer_cashback",
    │   │     amount=19.00, balanceBefore=301, balanceAfter=320
    │   └── mobile_recharge: status="success", cashback.credited=true, cashback.amount=19.00
    │
    ├── 9. audit_logs/{autoId}: action="drive_offer.success"
    │
    └── 10. Return to Flutter: { success: true, status: "success", cashback: 19.00 }
```

### Flow C: Failed Recharge (ECARE Rejected)

```
User taps "Recharge ৳50 to 01712345678"
    │
    ├── 1–4. Same initiate + debit flow (wallet 500 → 450)
    │
    ├── 5. Call ECARE → { STATUS: "FAILED", RECHARGE_STATUS: "FAILED", MESSAGE: "Recharge Request Failed." }
    │
    ├── 6. REFUND (Firestore Transaction):
    │   ├── users/{uid}/wallet/balanceBDT: 450 → 500 (refund ৳50)
    │   ├── wallet_transactions/{autoId}: type="credit", source="recharge_refund", amount=50
    │   └── mobile_recharge: status="refunded", error={code:"FAILED", message:"..."}
    │
    ├── 7. audit_logs/{autoId}: action="recharge.refund"
    │
    └── 8. Return to Flutter: { success: false, status: "refunded", message: "Recharge failed. Amount refunded." }
```

### Flow D: Timeout / Pending Verification

```
Recharge submitted → ECARE returns RECEIVED
    │
    ├── Poll 1 (5s): PROCESSING
    ├── Poll 2 (10s): PROCESSING
    ├── Poll 3 (15s): PENDING
    ├── ... (continues polling with backoff)
    ├── Poll 10 (60s): PROCESSING
    │
    ├── Max polls exceeded:
    │   ├── mobile_recharge: status="pending_verification", ecareStatus="PROCESSING"
    │   ├── NO refund yet (ECARE may still process)
    │   ├── NO cashback yet
    │   └── Admin alert: "Recharge SHR_... stuck in PROCESSING after 10 polls"
    │
    └── Admin manually checks later → resolves as success or failed
```

---

## 9️⃣ Flutter Feature Implementation Guide

### Folder Structure

```
lib/features/mobile_recharge/
├── controllers/
│   └── mobile_recharge_controller.dart    # State + logic
├── models/
│   ├── recharge_model.dart                # Mobile recharge document model
│   └── drive_offer_model.dart             # Drive offer pack model
├── repositories/
│   └── mobile_recharge_repository.dart    # Cloud Function calls
├── screens/
│   ├── mobile_recharge_screen.dart        # Main recharge screen
│   ├── drive_offers_screen.dart           # Browse offers screen
│   └── recharge_history_screen.dart       # Transaction history
└── widgets/
    ├── operator_selector.dart             # Operator picker
    ├── number_type_selector.dart          # Number type picker
    ├── phone_number_input.dart            # Phone number field
    ├── amount_input.dart                  # Amount field with offer hint
    ├── drive_offer_suggestion_card.dart   # "Offer available at this amount" card
    ├── drive_offer_card.dart              # Single offer pack card
    ├── drive_offer_filter_bar.dart        # Filter chips
    ├── recharge_confirmation_dialog.dart  # Confirm before recharge
    ├── recharge_history_tile.dart         # History list item
    └── recharge_status_badge.dart         # Status indicator
```

### Controller Registration

```dart
// In InitialBinding
Get.lazyPut(() => MobileRechargeController());

// In controller
class MobileRechargeController extends GetxController {
  static MobileRechargeController get instance => Get.find();
  // ...
}
```

### Smart Offer Detection (Amount Input)

When the user types a recharge amount, the controller debounces (300ms) and checks:

```dart
void onAmountChanged(String value) {
  _debouncer.run(() async {
    final amount = int.tryParse(value);
    if (amount == null || amount < 10) return;
    
    // Search for matching drive offers
    final offers = await repository.searchDriveOffers(
      amount: amount,
      operator: selectedOperator.value,
    );
    
    matchingOffers.value = offers;
    // If offers found, show suggestion card in UI
  });
}
```

---

## 🔒 Security, Compliance & Google Play Policy

### Google Play Developer Policy Compliance

| Policy Area | How shirah Complies |
|-------------|---------------------|
| **Payments & In-app Purchases** | Mobile recharge is a **real-world service** purchase (telecom top-up), NOT a digital good. Google Play billing is NOT required for real-world goods/services. This falls under the same category as food delivery, ride-hailing, or utility bill payments. |
| **Real-Money Transactions** | Users spend pre-loaded wallet balance (BDT). The wallet is funded via external payment methods (bKash, Nagad, bank transfer) — NOT via Google Play billing. This is compliant with Google Play's [Payments Policy for real-world goods](https://support.google.com/googleplay/android-developer/answer/9858738). |
| **Cashback / Rewards** | Cashback is a standard merchant loyalty mechanism (like credit card cashback). It is NOT gambling, lottery, or contest. Users earn a fixed, pre-determined cashback amount — no randomness, no chance-based rewards. |
| **No Gambling / Lottery** | No random rewards. Cashback is deterministic: 1.5% for recharge, fixed commission for drive offers. |
| **Transparency** | Exact cashback amount is shown BEFORE the user confirms the transaction. No hidden fees, no surprises. |
| **Refund Policy** | If recharge fails at ECARE, wallet is automatically refunded. User sees the refund in wallet history with clear explanation. |
| **User Data** | Phone numbers entered for recharge are NOT stored for marketing. They are stored only in transaction history for user reference and support resolution. |
| **Third-Party Service** | ECARE is a licensed telecom aggregator in Bangladesh. shirah acts as a reseller/agent — standard business model for fintech/super-apps in Bangladesh. |

### Security Architecture

| Layer | Protection |
|-------|------------|
| **API Credentials** | Stored as Firebase environment secrets (`functions.config()` or Secret Manager). Never in client code, never in Git. |
| **Client → Server** | All recharge logic runs in Cloud Functions. Flutter NEVER calls ECARE directly. |
| **Server → ECARE** | HTTP GET from Cloud Functions (server-to-server). IP whitelisting can be configured with ECARE if supported. |
| **Wallet Integrity** | All wallet operations use Firestore transactions (atomic read-modify-write). No race conditions. |
| **Idempotency** | Unique `refid` per request prevents double-charging. ECARE rejects duplicate `refid`. |
| **Rate Limiting** | Max 20 recharges/day and max 10 drive offer purchases/day per user (configurable in `configurations/app_settings`). |
| **Audit Trail** | Every transaction creates an `audit_logs` entry. Every wallet change creates a `wallet_transactions` entry. Full traceability. |
| **Anti-Abuse** | Suspended/banned users cannot transact. Locked wallets cannot transact. Risk-level monitoring via existing system. |
| **Input Validation** | Phone number format validation (11-digit BD number starting with 01). Amount range validation. Operator code validation. All server-side. |

### Data Privacy

| Data | Storage | Retention | Access |
|------|---------|-----------|--------|
| Destination phone number | `mobile_recharge/{refid}/phone` | Indefinite (transaction history) | User (own history) + Admin |
| Recharge amount | `mobile_recharge/{refid}/amount` | Indefinite | User + Admin |
| ECARE transaction IDs | `mobile_recharge/{refid}/ecare` | Indefinite | Admin only |
| Wallet balance snapshots | `mobile_recharge/{refid}/wallet` | Indefinite | User + Admin |

---

## 1️⃣1️⃣ Error Handling & Edge Cases

### Error Scenarios

| Scenario | Detection | Response |
|----------|-----------|----------|
| Insufficient wallet balance | `balanceBDT < amount` | Reject immediately, show "Insufficient balance. Please add funds." |
| Wallet locked | `wallet.locked == true` | Reject immediately, show "Your wallet is locked. Contact support." |
| Account not verified | `status.verified == false` | Reject immediately, show "Please verify your account first." |
| Account suspended/banned | `status.accountState != "active"` | Reject immediately, show "Your account is restricted." |
| Invalid phone number | Regex validation | Reject immediately, show "Enter a valid 11-digit Bangladeshi number." |
| Invalid operator/amount | Validation | Reject immediately with specific error message. |
| ECARE API timeout | HTTP timeout (30s) | Mark as "pending_verification", do NOT refund yet, alert admin. |
| ECARE API unreachable | Network error | Refund wallet immediately, mark as "failed", log error. |
| ECARE LOWBALANCE | ECARE response | Refund user wallet, alert admin "ECARE balance low: ৳{balance}". |
| ECARE DUPLICATE | ECARE response | Should never happen (unique refid). Log critical error. Refund user. |
| ECARE REJECT (invalid creds) | ECARE response | Refund user, alert admin immediately — credentials may be compromised. |
| Firestore transaction failure | Exception | Retry once. If still fails, return error to user. No wallet change. |
| Double-tap / duplicate request | Client-side debounce + server-side refid uniqueness | Only one request processes. |

### ECARE Balance Monitoring

Cloud Functions should check ECARE balance (`BLCK`) periodically:

```
Schedule: Every 2 hours (via Cloud Scheduler)
Alert Thresholds:
  - MAIN_BALANCE < ৳1,000  → Warning notification to admin
  - MAIN_BALANCE < ৳500   → Critical alert — disable recharge feature temporarily
  - MAIN_BALANCE < ৳100   → Emergency — disable all recharge/offer features
```

### Operator Code Mapping (Bidirectional)

```typescript
// ECARE Recharge API numeric codes → Offer API string codes
const OPERATOR_MAP = {
  // Recharge code → Offer response code → Display name
  "7": { offerCode: "GP", name: "Grameenphone" },  // also accepts "3"
  "3": { offerCode: "GP", name: "Grameenphone" },
  "4": { offerCode: "BL", name: "Banglalink" },     // also accepts "9"
  "9": { offerCode: "BL", name: "Banglalink" },
  "8": { offerCode: "RB", name: "Robi" },
  "6": { offerCode: "AR", name: "Airtel" },
  "5": { offerCode: "TL", name: "Teletalk" },
};

// Reverse: Offer code → Recharge code
const OFFER_TO_RECHARGE_MAP = {
  "GP": "7",
  "BL": "4",
  "RB": "8",
  "AR": "6",
  "TL": "5",
};
```

---

## 1️⃣2️⃣ ECARE Provider Contact

| Info | Value |
|------|-------|
| Company | ECARE Technology |
| Website | `www.ect.com.bd` |
| Email | `ecarebd247@gmail.com` |
| Skype | `ecarebd247` |
| Helpline | `+88 01613094989` (WhatsApp & IMO) |
| Address | House #32/B/1, Road #16/B, Comfort Housing Society, Adabor, Dhaka-1207, Bangladesh |
| API Docs Version | `2021.11.20.007` |
| Original PDF | `documents/mobileRecharge/Ecare_Topup_API_20_11_2021.pdf` |
| Offer Response Sample | `documents/mobileRecharge/offer_pack_response.json` |

---

## 📌 Quick Constants Reference

```
ECARE Base URL:         http://118.179.129.98/myportal/api/rechargeapi/recharge_api_thirdparty.php
Service Codes:          MRC (recharge), MRCSTATUS (status check), BLCK (balance), OFFERPACK (offers)
refid Format:           SHR_{timestamp_ms}_{random_6}
Recharge Cashback:      1.5% of amount
Drive Offer Cashback:   _commission_amount from pack
Min Recharge:           ৳10
Max Recharge:           ৳5,000
Max Recharges/Day:      20
Max Offer Purchases/Day: 10
Offer Cache TTL:        1 hour
Status Poll Max:        10 attempts
Status Poll Backoff:    5s → 10s → 15s → 30s → 60s
```

---

## ⚙️ Existing System Integration Points

### Collections Written By Recharge Features

| Collection | Why |
|-----------|------|
| `mobile_recharge` | **NEW** — primary transaction history |
| `drive_offer_cache` | **NEW** — cached offer packs |
| `users` | Wallet balance increment/decrement |
| `wallet_transactions` | Debit, cashback credit, refund records |
| `audit_logs` | Every recharge action logged |

### Constants to Add in `functions/src/config/constants.ts`

```typescript
// MOBILE RECHARGE CONSTANTS
export const RECHARGE_TYPES = {
  RECHARGE: "recharge",
  DRIVE_OFFER: "drive_offer",
} as const;

export const RECHARGE_STATUS = {
  INITIATED: "initiated",
  SUBMITTED: "submitted",
  PROCESSING: "processing",
  SUCCESS: "success",
  FAILED: "failed",
  REFUNDED: "refunded",
  PENDING_VERIFICATION: "pending_verification",
} as const;

// Add to COLLECTIONS
MOBILE_RECHARGE: "mobile_recharge",
DRIVE_OFFER_CACHE: "drive_offer_cache",

// Add to TRANSACTION_SOURCES
RECHARGE_DEBIT: "recharge_debit",
DRIVE_OFFER_CASHBACK: "drive_offer_cashback",
RECHARGE_REFUND: "recharge_refund",

// Add to AUDIT_ACTIONS
RECHARGE_INITIATE: "recharge.initiate",
RECHARGE_SUCCESS: "recharge.success",
RECHARGE_FAILED: "recharge.failed",
RECHARGE_REFUND: "recharge.refund",
DRIVE_OFFER_INITIATE: "drive_offer.initiate",
DRIVE_OFFER_SUCCESS: "drive_offer.success",
DRIVE_OFFER_FAILED: "drive_offer.failed",
DRIVE_OFFER_REFUND: "drive_offer.refund",
```

### `configurations/app_settings` — New Section

```
configurations/app_settings
└── mobileRecharge : Map
    ├── enabled : Boolean                # Feature flag (default: true)
    ├── minAmountBDT : Number            # Min recharge amount (default: 10)
    ├── maxAmountBDT : Number            # Max recharge amount (default: 5000)
    ├── cashbackPercent : Number          # Recharge cashback % (default: 1.5)
    ├── maxDailyRecharges : Number        # Max recharges per day (default: 20)
    ├── maxDailyOfferPurchases : Number   # Max offer purchases per day (default: 10)
    ├── offerCacheTTLMinutes : Number     # Offer cache duration (default: 60)
    ├── statusPollMaxAttempts : Number    # Max status check polls (default: 10)
    └── ecareBalanceAlertThreshold : Number # Alert when ECARE balance below this (default: 1000)
```

---

**END OF ECARE MOBILE RECHARGE & DRIVE OFFER DOCUMENTATION**
