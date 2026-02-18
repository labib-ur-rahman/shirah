# 📱 SHIRAH User App Mobile Recharge & Drive Offer — Implementation Guide (Enterprise)

**Document Type:** User App Implementation Guide  
**Version:** 1.0  
**Last Updated:** February 17, 2026  
**Target Audience:** Flutter Developers, AI Agents, Tech Leads  

---

**Purpose**
This document explains how to implement **Mobile Recharge** and **Drive Offer Purchase** in the **User/Client App**, aligned with the existing backend (Firebase Functions + ECARE). It is written to be easily understood by both humans and AI agents, with clear rules, steps, and best practices.

---

**Table of Contents**
1. System Overview
2. Backend Contracts (Must Follow)
3. Core Business Rules
4. User App Architecture
5. Mobile Recharge Flow
6. Instant Offer Detection (New Requirement)
7. Drive Offer Purchase Flow
8. Recharge History Flow
9. Data Models (Suggested)
10. Error Handling & UX Messaging
11. Best Practices
12. Things to Avoid
13. Tips, Pros, Cons
14. Implementation Checklist

---

**1. System Overview**
The user app calls Firebase callable functions that interact with the ECARE gateway. The client app **must never** call ECARE directly.

**Flow (High Level)**
1. User enters phone + amount + operator + number type.
2. App calls Firebase function.
3. Backend validates, debits wallet, calls ECARE, polls status.
4. Backend stores transaction and applies cashback or refunds.

---

**2. Backend Contracts (Must Follow)**
Source of truth:
- `functions/src/features/mobile-recharge/mobile-recharge-operations.ts`
- `functions/src/config/constants.ts`

**Callable Functions (User App)**
- `initiateRecharge`
- `getDriveOffers`
- `searchDriveOffers`
- `getRechargeHistory`

**Region**
- Always call functions in `asia-south1`.

**Functions Instance**
```dart
final functions = FirebaseFunctions.instanceFor(region: 'asia-south1');
```

---

**3. Core Business Rules**
These rules are enforced server-side, but you must also validate client-side for good UX.

1. Phone number must be 11 digits and start with `01`.
2. Recharge amount must be between ৳20 and ৳5000.
3. Regular recharge amount must be a **round figure** (ends with 0).
4. Drive offer purchase amount must match a valid offer.
5. Daily limits: 20 recharges, 10 drive offers.

---

**4. User App Architecture**
Recommended structure:

1. API Client
2. Repository
3. Controller/ViewModel
4. UI Screens

**Suggested Dart Structure**
- `lib/features/mobile_recharge/data/mobile_recharge_api.dart`
- `lib/features/mobile_recharge/data/mobile_recharge_repository.dart`
- `lib/features/mobile_recharge/controllers/mobile_recharge_controller.dart`
- `lib/features/mobile_recharge/views/recharge_screen.dart`
- `lib/features/mobile_recharge/views/drive_offer_screen.dart`
- `lib/features/mobile_recharge/views/recharge_history_screen.dart`

---

**5. Mobile Recharge Flow**

**UI Fields**
- Phone Number
- Operator
- Number Type (Prepaid/Postpaid)
- Amount
- Submit Button

**Client Validation**
1. Phone not empty, starts with `01`, length 11.
2. Operator auto-detected from prefix must match selected operator.
3. Amount must be integer > 0.
4. If no offer detected, amount must end in `0`.

**Submit Payload (Regular Recharge)**
```dart
await functions.httpsCallable('initiateRecharge').call({
  'phone': phone,
  'operator': rechargeOperatorCode,
  'numberType': numberType,
  'amount': amount,
  'type': 'recharge',
});
```

**Operator Code Mapping**
Recharge operator codes are **numbers**, not GP/BL strings.

| Operator | Recharge Code |
|---|---|
| GP | 7 or 3 |
| BL | 4 or 9 |
| RB | 8 |
| AR | 6 |
| TL | 5 |

---

**6. Instant Offer Detection (New Requirement)**

**Requirement**
If user enters an amount that matches any drive offer for the same operator, show the offer immediately. If user proceeds, this must be treated as a **drive offer** purchase even if they started from the recharge screen.

**How**
Use `searchDriveOffers(amount, operator)`.

**Important**
- `operator` here is the **offer group** (`GP`, `BL`, `RB`, `AR`, `TL`), not numeric.

**Debounce**
- Debounce input by 350–500ms.
- Only search when amount is valid integer and operator is known.

**Suggested UX**
1. Show “Matched Offer” card below amount.
2. Primary CTA: “Use Offer Pack”.
3. Optional secondary CTA: “Regular Recharge”.

**Behavior Rules**
1. If amount **ends with 0** and offer exists: (In round figure amount always no offer exists)
   - Default allow normal recharge.
2. If amount **does not end with 0** and offer exists:
   - Force offer purchase.
3. If no offer exists:
   - Only allow normal recharge.

**Callable**
```dart
await functions.httpsCallable('searchDriveOffers').call({
  'amount': amount,
  'operator': offerOperatorCode, // e.g. 'GP'
});
```

---

**7. Drive Offer Purchase Flow**

**UI Steps**
1. User selects operator tab.
2. User filters by offer type.
3. App fetches offers via `getDriveOffers`.
4. User taps offer → shows bottom sheet.
5. User enters phone and confirms purchase.

**Submit Payload (Drive Offer)**
```dart
await functions.httpsCallable('initiateRecharge').call({
  'phone': phone,
  'operator': rechargeOperatorCode,
  'numberType': offer.numberType,
  'amount': offer.amount,
  'type': 'drive_offer',
  'offerDetails': {
    'offerType': offer.offerType,
    'minutePack': offer.minutePack,
    'internetPack': offer.internetPack,
    'smsPack': offer.smsPack,
    'callratePack': offer.callratePack,
    'validity': offer.validity,
    'commissionAmount': offer.commissionAmount,
  },
});
```

**Offer Operator Mapping**
Use this mapping to convert offer operator group to recharge operator code:

| Offer Operator | Recharge Code |
|---|---|
| GP | 7 |
| BL | 4 |
| RB | 8 |
| AR | 6 |
| TL | 5 |

---

**8. Recharge History Flow**

**Callable**
```dart
await functions.httpsCallable('getRechargeHistory').call({
  'limit': 20,
  'startAfter': lastDocId,
});
```

**Fields to Show**
- Phone
- Amount
- Status
- Operator
- Date
- Cashback

**Statuses**
- `initiated`
- `submitted`
- `processing`
- `success`
- `failed`
- `refunded`
- `pending_verification`

---

**9. Data Models (Suggested)**

**DriveOfferItem**
- operator
- numberType
- offerType
- minutePack
- internetPack
- smsPack
- callratePack
- validity
- amount
- commissionAmount

**RechargeRequest**
- phone
- operator
- numberType
- amount
- type
- offerDetails (optional)

**RechargeTransaction**
- refid
- type
- amount
- status
- phone
- createdAt
- operator
- offer (optional)

---

**10. Error Handling & UX Messaging**

**User‑Friendly Errors**
- Invalid phone → “Enter a valid 11‑digit number.”
- Insufficient wallet → “Insufficient balance.”
- Amount invalid → “Recharge amount must end with 0.”
- Daily limit → “Daily limit reached. Try again tomorrow.”

**Timeout Handling**
Backend may time out. If `FirebaseFunctionsException.code == 'deadline-exceeded'`:
- Show: “Request submitted. Status will update shortly.”
- Treat as success for UI flow.

---

**11. Best Practices**
1. Centralize operator mapping in one file.
2. Validate on client before server call.
3. Debounce offer detection.
4. Always disable submit while in progress.
5. Log errors with metadata.
6. Cache offers by operator for faster UI.

---

**12. Things to Avoid**
1. Calling ECARE from client app.
2. Passing `GP/BL` into `initiateRecharge` operator field.
3. Allowing non‑round amounts for normal recharge.
4. Sending drive offer purchase without `offerDetails`.
5. Calling `searchDriveOffers` on every keystroke without debounce.

---

**13. Tips, Pros, Cons**

**Tips**
- Show matched offer immediately to improve conversion.
- Use a loading shimmer for offers to improve perceived speed.
- Always show the operator detected from phone prefix.

**Pros**
- Seamless recharge and offer purchase in one screen.
- Higher conversion through instant offer detection.
- Better user trust by validating client‑side.

**Cons**
- Requires strict mapping logic to avoid operator mismatch.
- Offer detection adds extra function calls (needs debounce).
- More UI states to handle (offer vs recharge).

---

**14. Implementation Checklist**

1. Setup Firebase Functions region `asia-south1`.
2. Implement operator prefix detection.
3. Implement mobile recharge form with validation.
4. Implement offer detection with debounce.
5. Implement drive offer list and purchase flow.
6. Implement recharge history screen.
7. Add error handling and timeout handling.
8. Test all cases including daily limits and invalid amounts.

---

**File References (Backend)**
- `functions/src/features/mobile-recharge/mobile-recharge-operations.ts`
- `functions/src/config/constants.ts`

**Reference UI (Admin)**
- `admin/drive_offer_screen.dart.reference`
- `admin/purchase_sheet_widget.dart.reference`
- `admin/recharge_dialog_widget.dart.reference`

---

**End of Document**
