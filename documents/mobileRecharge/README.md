# 📱 Mobile Recharge & Drive Offer System - Quick Start

**SHIRAH Business & Community Super App**

---

## 🎯 What Is This?

A complete mobile recharge and drive offer purchase system integrated with ECARE Technology (Bangladeshi telecom recharge gateway). Users can:
- Recharge any Bangladeshi mobile number (GP, BL, Robi, Airtel, Teletalk)
- Purchase data/minute/bundle packs at listed prices
- Earn 1.5% cashback on every transaction
- Track complete transaction history

---

## 🚀 Quick Setup (3 Steps)

### 1. Set ECARE Credentials

```bash
# Production
firebase functions:secrets:set ECARE_ACCESS_ID
firebase functions:secrets:set ECARE_ACCESS_PASS

# Or Local Development
# Copy functions/.env.example to functions/.env
# Add your credentials
```

### 2. Create Firestore Index

First query will provide a link. Click it or create manually:
- Collection: `mobile_recharge`
- Fields: `uid` (Ascending) + `createdAt` (Descending)

### 3. Test

```dart
// Check ECARE balance (Admin)
final result = await FirebaseFunctions
    .instanceFor(region: 'asia-south1')
    .httpsCallable('getEcareBalance')
    .call();
```

---

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| [SETUP_SUMMARY.md](./SETUP_SUMMARY.md) | 🚀 What was done & next steps |
| [IMPLEMENTATION_GUIDE.md](./IMPLEMENTATION_GUIDE.md) | 📖 Complete Flutter implementation guide (500+ lines) |
| [Ecare_Topup_API_20_11_2021.md](./Ecare_Topup_API_20_11_2021.md) | 🔧 ECARE API technical reference |

---

## 🎮 Available Functions

### For Users

```dart
// Recharge mobile number
initiateRecharge(phone, operator, numberType, amount, type, offerDetails?)

// Get drive offer packs
getDriveOffers(operator?, offerType?, minAmount?, maxAmount?)

// Search offers by exact amount
searchDriveOffers(amount, operator, offerType?)

// View my recharge history
getRechargeHistory(limit?, startAfter?)
```

### For Admins

```dart
// Check ECARE merchant balance
getEcareBalance()

// View all user transactions
getAdminRechargeHistory(limit?, startAfter?, status?, type?, uid?)

// View statistics dashboard
getRechargeStats(period?)

// Retry failed/pending transaction
adminRetryRecharge(refid)

// Check ECARE status
adminRechargeStatus(refid)

// Refresh drive offer cache
refreshDriveOfferCache()
```

---

## 💡 Key Features

✅ **Automatic Status Polling** - Polls ECARE 10 times for status updates  
✅ **Auto Cashback** - 1.5% credited immediately on success  
✅ **Auto Refund** - Wallet refunded automatically on failure  
✅ **Daily Limits** - 20 recharges + 10 drive offers per user per day  
✅ **Atomic Transactions** - Firestore transactions ensure data consistency  
✅ **Comprehensive Audit Trail** - Every action logged  
✅ **Admin Management** - Full visibility and control for admins  

---

## 🛠️ Technical Stack

- **Backend:** Firebase Cloud Functions (TypeScript, 2nd Gen)
- **Region:** asia-south1 (Mumbai, India)
- **Database:** Cloud Firestore
- **External API:** ECARE Technology HTTP API
- **Language:** TypeScript 5.7.3, Node.js 20

---

## 📊 Business Rules

| Rule | Value |
|------|-------|
| Min/Max Amount | ৳20 - ৳5,000 |
| Amount Increment | ৳10 |
| Cashback Rate | 1.5% |
| Daily Limit | 20 recharges / 10 offers |
| Offer Cache | 1 hour |

---

## 🐛 Troubleshooting

**Q: Drive offers not loading?**  
A: Admin needs to run `refreshDriveOfferCache()`

**Q: Transaction stuck in "pending"?**  
A: Admin can use `adminRetryRecharge(refid)` to check and complete

**Q: "Credentials not configured"?**  
A: Follow Step 1 in Quick Setup above

**Full troubleshooting guide:** [IMPLEMENTATION_GUIDE.md](./IMPLEMENTATION_GUIDE.md) Section 6

---

## 📞 ECARE Contact

- **Email:** info@ect.com.bd
- **Phone:** +88 01718-840256  
- **Website:** www.ect.com.bd

---

## 📦 Files Structure

```
functions/src/features/mobile-recharge/
└── mobile-recharge-operations.ts (1,020 lines)

documents/mobileRecharge/
├── README.md (this file)
├── SETUP_SUMMARY.md (deployment summary)
├── IMPLEMENTATION_GUIDE.md (complete guide)
├── Ecare_Topup_API_20_11_2021.md (API docs)
└── offer_pack_response.json (sample data)

Firestore Collections:
├── mobile_recharge/{refid}
└── drive_offer_cache/latest
```

---

**Version:** 1.0.0  
**Last Updated:** February 16, 2026  
**Status:** ✅ Production Ready (after ECARE credentials setup)
