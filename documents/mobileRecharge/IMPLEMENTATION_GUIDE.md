# 📱 SHIRAH Mobile Recharge & Drive Offer - Complete Implementation Guide

> **Document Type:** Implementation Guide  
> **Version:** 1.0  
> **Last Updated:** February 16, 2026  
> **Target Audience:** Flutter Developers, Backend Engineers, System Admins  

---

## 📋 Table of Contents

1. [System Architecture Overview](#1-system-architecture-overview)
2. [Initial Setup & Configuration](#2-initial-setup--configuration)
3. [User App Implementation](#3-user-app-implementation)
4. [Admin App Implementation](#4-admin-app-implementation)
5. [Testing Guide](#5-testing-guide)
6. [Troubleshooting](#6-troubleshooting)
7. [API Reference Quick Guide](#7-api-reference-quick-guide)

---

## 1. System Architecture Overview

### Flow Diagram

```
┌─────────────────┐
│   USER APP      │
│  (Flutter)      │
└────────┬────────┘
         │
         │ 1. User initiates recharge/offer purchase
         │
         ▼
┌─────────────────────────────────────────┐
│  Firebase Cloud Functions               │
│  (asia-south1 region)                   │
│                                          │
│  ├─ initiateRecharge()                  │
│  │   ├─ Validate user & wallet          │
│  │   ├─ Debit wallet (atomic)           │
│  │   ├─ Call ECARE API                  │
│  │   ├─ Poll status (10 attempts)       │
│  │   ├─ Credit cashback on success      │
│  │   └─ Refund on failure               │
│  │                                       │
│  ├─ getDriveOffers()                    │
│  ├─ getRechargeHistory()                │
│  └─ [...admin functions]                │
└──────────────┬──────────────────────────┘
               │
               │ 2. HTTP GET request
               │
               ▼
┌─────────────────────────────────────────┐
│  ECARE Technology API                   │
│  (Third-Party Telecom Gateway)          │
│                                          │
│  Base: http://118.179.129.98/...        │
│  Services:                               │
│    - MRC (Mobile Recharge)              │
│    - MRCSTATUS (Status Check)           │
│    - OFFERPACK (Drive Offer List)       │
│    - BLCK (Balance Check)               │
└─────────────────────────────────────────┘
```

### Data Storage (Firestore Collections)

| Collection | Purpose |
|------------|---------|
| `mobile_recharge` | Transaction history (refid as docId) |
| `drive_offer_cache` | Cached offer list (doc: "latest") |
| `wallet_transactions` | BDT wallet ledger |
| `users` | User wallet balance snapshot |

---

## 2. Initial Setup & Configuration

### 2.1 ECARE API Credentials Setup

#### Step 1: Get Credentials from ECARE

Contact ECARE Technology to get your credentials:
- **Email:** info@ect.com.bd  
- **Phone:** +88 01718-840256  
- **Website:** www.ect.com.bd

You will receive:
- `access_id` (Your API username)
- `access_pass` (Your API password)

#### Step 2: Configure Firebase Secrets (Production)

```bash
# Navigate to your project
cd s:\Business\shirah-admin

# Set ECARE credentials as Firebase secrets
firebase functions:secrets:set ECARE_ACCESS_ID
# When prompted, enter your actual access_id

firebase functions:secrets:set ECARE_ACCESS_PASS
# When prompted, enter your actual access_pass

# Deploy functions to activate secrets
firebase deploy --only functions
```

#### Step 3: Configure Local Development

Create a `.env` file in the `functions/` directory:

```bash
# functions/.env
ECARE_ACCESS_ID=your_actual_access_id
ECARE_ACCESS_PASS=your_actual_access_password
```

**⚠️ IMPORTANT:** Never commit `.env` to Git. It's already in `.gitignore`.

### 2.2 Firestore Indexes Setup

Create these composite indexes in Firebase Console:

**Index 1: For `getRechargeHistory()` (User)**
```
Collection: mobile_recharge
Fields:
  - uid (Ascending)
  - createdAt (Descending)
```

**Index 2: For `getAdminRechargeHistory()` (Admin - with status filter)**
```
Collection: mobile_recharge
Fields:
  - status (Ascending)
  - createdAt (Descending)
```

**Index 3: For `getAdminRechargeHistory()` (Admin - with type filter)**
```
Collection: mobile_recharge
Fields:
  - type (Ascending)
  - createdAt (Descending)
```

**Index 4: For `getAdminRechargeHistory()` (Admin - with uid filter)**
```
Collection: mobile_recharge
Fields:
  - uid (Ascending)
  - createdAt (Descending)
```

**How to create:**
1. Go to Firebase Console → Firestore Database → Indexes
2. Click "Create Index"
3. Enter the collection and fields as shown
4. Click "Create"

Alternatively, when you first run a query that needs an index, Firebase will throw an error with a direct link to create the index.

### 2.3 Verify Deployment

Check that all functions are deployed:

```bash
firebase functions:list | Select-String "recharge"
```

You should see:
- `initiateRecharge`
- `getDriveOffers`
- `searchDriveOffers`
- `getRechargeHistory`
- `getEcareBalance`
- `refreshDriveOfferCache`
- `adminRechargeStatus`
- `getAdminRechargeHistory`
- `getRechargeStats`
- `adminRetryRecharge`

---

## 3. User App Implementation

### 3.1 Mobile Recharge Feature

#### UI Flow

```
┌───────────────────────────────┐
│  Recharge Screen              │
│                               │
│  Phone Number: [01700000000]  │
│  Operator: [Grameenphone ▼]   │
│  Number Type: [Prepaid ▼]     │
│  Amount: [100৳]               │
│                               │
│  Your Balance: 5,000৳         │
│  Cashback (1.5%): 1.50৳       │
│                               │
│  [Recharge Now]               │
└───────────────────────────────┘
```

#### Flutter Implementation

**File:** `lib/modules/recharge/controllers/recharge_controller.dart`

```dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:get/get.dart';

class RechargeController extends GetxController {
  final _functions = FirebaseFunctions.instanceFor(region: 'asia-south1');
  
  final RxBool isLoading = false.obs;
  final RxString phone = ''.obs;
  final RxString operator = '7'.obs; // Default: Grameenphone
  final RxString numberType = '1'.obs; // Default: Prepaid
  final RxInt amount = 100.obs;
  
  // Operator codes mapping
  final operators = {
    '7': 'Grameenphone',
    '4': 'Banglalink',
    '8': 'Robi',
    '6': 'Airtel',
    '5': 'Teletalk',
  };
  
  // Number type mapping
  final numberTypes = {
    '1': 'Prepaid',
    '2': 'Postpaid',
    '3': 'Skitto',
    '4': 'PowerLoad',
  };
  
  // Calculate cashback (1.5%)
  double get cashback => (amount.value * 1.5) / 100;
  
  /// Initiate mobile recharge
  Future<void> initiateRecharge() async {
    // Validation
    if (phone.value.length != 11 || !phone.value.startsWith('01')) {
      AppHelpers.showError('Invalid phone number. Must be 11 digits starting with 01.');
      return;
    }
    
    if (amount.value < 20 || amount.value > 5000) {
      AppHelpers.showError('Amount must be between ৳20 and ৳5,000');
      return;
    }
    
    if (amount.value % 10 != 0) {
      AppHelpers.showError('Amount must be a round figure (ending in 0)');
      return;
    }
    
    try {
      isLoading.value = true;
      
      final result = await _functions.httpsCallable('initiateRecharge').call({
        'phone': phone.value,
        'operator': operator.value,
        'numberType': numberType.value,
        'amount': amount.value,
        'type': 'recharge',
      });
      
      final data = result.data as Map<String, dynamic>;
      
      if (data['success'] == true) {
        final refid = data['data']['refid'];
        final status = data['data']['status'];
        final cashbackAmount = data['data']['cashback'];
        
        if (status == 'success') {
          AppHelpers.showSuccess(
            'Recharge successful! Cashback ৳$cashbackAmount credited.'
          );
          // Navigate to recharge history or home
          Get.back();
        } else if (status == 'pending_verification') {
          AppHelpers.showInfo(
            'Recharge is being processed. We will update you shortly.'
          );
          Get.back();
        } else {
          AppHelpers.showError(data['message'] ?? 'Recharge failed');
        }
      } else {
        AppHelpers.showError(data['message'] ?? 'Recharge failed');
      }
      
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'failed-precondition') {
        if (e.message?.contains('Insufficient wallet balance') == true) {
          AppHelpers.showError('Insufficient wallet balance. Please add funds.');
        } else if (e.message?.contains('Daily limit reached') == true) {
          AppHelpers.showError('Daily recharge limit reached (20 per day)');
        } else {
          AppHelpers.showError(e.message ?? 'Operation failed');
        }
      } else {
        AppHelpers.showError(e.message ?? 'An error occurred');
      }
    } catch (e) {
      AppHelpers.showError('An unexpected error occurred');
      LoggerService.error('Recharge error: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
```

**File:** `lib/modules/recharge/views/recharge_screen.dart`

```dart
class RechargeScreen extends GetView<RechargeController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mobile Recharge')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Phone Number Input
            CustomTextField(
              label: 'Phone Number',
              hint: '01700000000',
              keyboardType: TextInputType.phone,
              maxLength: 11,
              onChanged: (value) => controller.phone.value = value,
            ),
            
            const SizedBox(height: 16),
            
            // Operator Dropdown
            Obx(() => CustomDropdown<String>(
              label: 'Operator',
              value: controller.operator.value,
              items: controller.operators.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ))
                  .toList(),
              onChanged: (value) => controller.operator.value = value!,
            )),
            
            const SizedBox(height: 16),
            
            // Number Type Dropdown
            Obx(() => CustomDropdown<String>(
              label: 'Number Type',
              value: controller.numberType.value,
              items: controller.numberTypes.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ))
                  .toList(),
              onChanged: (value) => controller.numberType.value = value!,
            )),
            
            const SizedBox(height: 16),
            
            // Amount Input
            Obx(() => CustomTextField(
              label: 'Amount',
              hint: '100',
              keyboardType: TextInputType.number,
              prefixText: '৳',
              initialValue: controller.amount.value.toString(),
              onChanged: (value) {
                final amt = int.tryParse(value) ?? 0;
                controller.amount.value = amt;
              },
            )),
            
            const SizedBox(height: 24),
            
            // Cashback Info
            Obx(() => InfoCard(
              title: 'Recharge Summary',
              items: [
                InfoRow('Amount', '৳${controller.amount.value}'),
                InfoRow('Cashback (1.5%)', '৳${controller.cashback.toStringAsFixed(2)}', 
                        color: AppColors.green),
              ],
            )),
            
            const Spacer(),
            
            // Recharge Button
            Obx(() => PrimaryButton(
              text: 'Recharge Now',
              isLoading: controller.isLoading.value,
              onPressed: controller.initiateRecharge,
            )),
          ],
        ),
      ),
    );
  }
}
```

### 3.2 Drive Offer Purchase Feature

#### UI Flow

```
┌───────────────────────────────┐
│  Drive Offers                 │
│                               │
│  Filter: [Grameenphone ▼]     │
│  Type: [Internet ▼]           │
│                               │
│  ┌─────────────────────────┐  │
│  │ 1GB Internet            │  │
│  │ Validity: 7 days        │  │
│  │ ৳50                     │  │
│  │ Cashback: ৳0.75         │  │
│  │ [Purchase]              │  │
│  └─────────────────────────┘  │
│                               │
│  ┌─────────────────────────┐  │
│  │ 2GB Internet            │  │
│  │ Validity: 7 days        │  │
│  │ ৳99                     │  │
│  │ Cashback: ৳1.49         │  │
│  │ [Purchase]              │  │
│  └─────────────────────────┘  │
└───────────────────────────────┘
```

#### Flutter Implementation

**File:** `lib/modules/recharge/controllers/drive_offer_controller.dart`

```dart
class DriveOfferController extends GetxController {
  final _functions = FirebaseFunctions.instanceFor(region: 'asia-south1');
  
  final RxBool isLoading = false.obs;
  final RxList<DriveOffer> offers = <DriveOffer>[].obs;
  final RxString selectedOperator = ''.obs;
  final RxString selectedOfferType = ''.obs;
  
  final operators = {
    '': 'All Operators',
    '7': 'Grameenphone',
    '4': 'Banglalink',
    '8': 'Robi',
    '6': 'Airtel',
    '5': 'Teletalk',
  };
  
  final offerTypes = {
    '': 'All Types',
    'IN': 'Internet',
    'MN': 'Minutes',
    'BD': 'Bundle',
  };
  
  @override
  void onInit() {
    super.onInit();
    fetchOffers();
  }
  
  /// Fetch drive offers with filters
  Future<void> fetchOffers() async {
    try {
      isLoading.value = true;
      
      final result = await _functions.httpsCallable('getDriveOffers').call({
        if (selectedOperator.value.isNotEmpty) 'operator': selectedOperator.value,
        if (selectedOfferType.value.isNotEmpty) 'offerType': selectedOfferType.value,
      });
      
      final data = result.data as Map<String, dynamic>;
      
      if (data['success'] == true) {
        final offerList = data['data']['offers'] as List;
        offers.value = offerList
            .map((json) => DriveOffer.fromMap(json as Map<String, dynamic>))
            .toList();
      }
      
    } on FirebaseFunctionsException catch (e) {
      AppHelpers.showError(e.message ?? 'Failed to load offers');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Purchase drive offer
  Future<void> purchaseOffer(DriveOffer offer, String phone) async {
    try {
      isLoading.value = true;
      
      final result = await _functions.httpsCallable('initiateRecharge').call({
        'phone': phone,
        'operator': offer.operator,
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
      
      final data = result.data as Map<String, dynamic>;
      
      if (data['success'] == true) {
        final status = data['data']['status'];
        final cashbackAmount = data['data']['cashback'];
        
        if (status == 'success') {
          AppHelpers.showSuccess(
            'Offer pack activated! Cashback ৳$cashbackAmount credited.'
          );
          Get.back();
        } else {
          AppHelpers.showError(data['message'] ?? 'Purchase failed');
        }
      } else {
        AppHelpers.showError(data['message'] ?? 'Purchase failed');
      }
      
    } on FirebaseFunctionsException catch (e) {
      AppHelpers.showError(e.message ?? 'Purchase failed');
    } finally {
      isLoading.value = false;
    }
  }
}
```

**Data Model:** `lib/data/models/drive_offer.dart`

```dart
class DriveOffer {
  final String operator;
  final String operatorName;
  final String numberType;
  final String offerType;
  final String offerTypeName;
  final String minutePack;
  final String internetPack;
  final String smsPack;
  final String callratePack;
  final String validity;
  final int amount;
  final double commissionAmount;
  final String status;
  
  DriveOffer({
    required this.operator,
    required this.operatorName,
    required this.numberType,
    required this.offerType,
    required this.offerTypeName,
    required this.minutePack,
    required this.internetPack,
    required this.smsPack,
    required this.callratePack,
    required this.validity,
    required this.amount,
    required this.commissionAmount,
    required this.status,
  });
  
  factory DriveOffer.fromMap(Map<String, dynamic> map) {
    return DriveOffer(
      operator: map['operator'] ?? '',
      operatorName: map['operatorName'] ?? '',
      numberType: map['numberType'] ?? '',
      offerType: map['offerType'] ?? '',
      offerTypeName: map['offerTypeName'] ?? '',
      minutePack: map['minutePack'] ?? '-',
      internetPack: map['internetPack'] ?? '-',
      smsPack: map['smsPack'] ?? '-',
      callratePack: map['callratePack'] ?? '-',
      validity: map['validity'] ?? '',
      amount: map['amount'] ?? 0,
      commissionAmount: (map['commissionAmount'] ?? 0).toDouble(),
      status: map['status'] ?? '',
    );
  }
}
```

### 3.3 Recharge History (User View)

**File:** `lib/modules/recharge/controllers/history_controller.dart`

```dart
class RechargeHistoryController extends GetxController {
  final _functions = FirebaseFunctions.instanceFor(region: 'asia-south1');
  
  final RxBool isLoading = false.obs;
  final RxList<RechargeTransaction> transactions = <RechargeTransaction>[].obs;
  String? lastDocId;
  
  @override
  void onInit() {
    super.onInit();
    fetchHistory();
  }
  
  /// Fetch user's recharge history
  Future<void> fetchHistory({bool loadMore = false}) async {
    if (isLoading.value) return;
    
    try {
      isLoading.value = true;
      
      final result = await _functions.httpsCallable('getRechargeHistory').call({
        'limit': 20,
        if (loadMore && lastDocId != null) 'startAfter': lastDocId,
      });
      
      final data = result.data as Map<String, dynamic>;
      
      if (data['success'] == true) {
        final txList = data['data']['transactions'] as List;
        final newTxs = txList
            .map((json) => RechargeTransaction.fromMap(json as Map<String, dynamic>))
            .toList();
        
        if (loadMore) {
          transactions.addAll(newTxs);
        } else {
          transactions.value = newTxs;
        }
        
        if (newTxs.isNotEmpty) {
          lastDocId = newTxs.last.refid;
        }
      }
      
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'failed-precondition' && e.message?.contains('index') == true) {
        AppHelpers.showError(
          'Database index required. Please contact support to enable recharge history.'
        );
      } else {
        AppHelpers.showError(e.message ?? 'Failed to load history');
      }
    } finally {
      isLoading.value = false;
    }
  }
}
```

**Data Model:** `lib/data/models/recharge_transaction.dart`

```dart
class RechargeTransaction {
  final String refid;
  final String uid;
  final String type; // 'recharge' or 'drive_offer'
  final String phone;
  final String operatorName;
  final String numberTypeName;
  final int amount;
  final String status;
  final double cashbackAmount;
  final bool cashbackCredited;
  final DateTime createdAt;
  final DateTime? completedAt;
  
  // Drive offer details (null for regular recharge)
  final String? offerTypeName;
  final String? internetPack;
  final String? minutePack;
  final String? validity;
  
  RechargeTransaction({
    required this.refid,
    required this.uid,
    required this.type,
    required this.phone,
    required this.operatorName,
    required this.numberTypeName,
    required this.amount,
    required this.status,
    required this.cashbackAmount,
    required this.cashbackCredited,
    required this.createdAt,
    this.completedAt,
    this.offerTypeName,
    this.internetPack,
    this.minutePack,
    this.validity,
  });
  
  factory RechargeTransaction.fromMap(Map<String, dynamic> map) {
    return RechargeTransaction(
      refid: map['refid'] ?? '',
      uid: map['uid'] ?? '',
      type: map['type'] ?? 'recharge',
      phone: map['phone'] ?? '',
      operatorName: map['operatorName'] ?? '',
      numberTypeName: map['numberTypeName'] ?? '',
      amount: map['amount'] ?? 0,
      status: map['status'] ?? '',
      cashbackAmount: (map['cashback']?['amount'] ?? 0).toDouble(),
      cashbackCredited: map['cashback']?['credited'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      completedAt: map['completedAt'] != null 
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      offerTypeName: map['offer']?['offerTypeName'],
      internetPack: map['offer']?['internetPack'],
      minutePack: map['offer']?['minutePack'],
      validity: map['offer']?['validity'],
    );
  }
  
  String get statusDisplay {
    switch (status) {
      case 'success':
        return 'Successful';
      case 'failed':
        return 'Failed';
      case 'refunded':
        return 'Refunded';
      case 'pending_verification':
        return 'Pending';
      case 'processing':
        return 'Processing';
      default:
        return status.capitalize!;
    }
  }
  
  Color get statusColor {
    switch (status) {
      case 'success':
        return AppColors.green;
      case 'failed':
      case 'refunded':
        return AppColors.red;
      case 'pending_verification':
      case 'processing':
        return AppColors.orange;
      default:
        return AppColors.textSecondary;
    }
  }
}
```

---

## 4. Admin App Implementation

### 4.1 Check ECARE Balance

**File:** `lib/modules/admin/controllers/ecare_admin_controller.dart`

```dart
class EcareAdminController extends GetxController {
  final _functions = FirebaseFunctions.instanceFor(region: 'asia-south1');
  
  final RxBool isLoading = false.obs;
  final RxString mainBalance = '0.00'.obs;
  final RxString stockBalance = '0.00'.obs;
  final RxString commissionType = '-'.obs;
  final RxString commissionRate = '-'.obs;
  
  /// Fetch ECARE merchant balance
  Future<void> fetchBalance() async {
    try {
      isLoading.value = true;
      
      final result = await _functions.httpsCallable('getEcareBalance').call();
      
      final data = result.data as Map<String, dynamic>;
      
      if (data['success'] == true) {
        final balanceData = data['data'] as Map<String, dynamic>;
        mainBalance.value = balanceData['MAIN_BALANCE'] ?? '0.00';
        stockBalance.value = balanceData['STOCK_BALANCE'] ?? '0.00';
        commissionType.value = balanceData['COMMISSION_TYPE'] ?? '-';
        commissionRate.value = balanceData['COMMISSION_RATE'] ?? '-';
        
        AppHelpers.showSuccess('Balance updated');
      }
      
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'permission-denied') {
        AppHelpers.showError('Admin access required');
      } else {
        AppHelpers.showError(e.message ?? 'Failed to fetch balance');
      }
    } finally {
      isLoading.value = false;
    }
  }
}
```

**UI Screen:**

```dart
class EcareBalanceScreen extends GetView<EcareAdminController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ECARE Balance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.fetchBalance,
          ),
        ],
      ),
      body: Obx(() => controller.isLoading.value
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  StatCard(
                    title: 'Main Balance',
                    value: '৳${controller.mainBalance.value}',
                    icon: Icons.account_balance_wallet,
                    color: AppColors.green,
                  ),
                  const SizedBox(height: 16),
                  StatCard(
                    title: 'Stock Balance',
                    value: '৳${controller.stockBalance.value}',
                    icon: Icons.inventory,
                    color: AppColors.blue,
                  ),
                  const SizedBox(height: 16),
                  InfoCard(
                    title: 'Commission Info',
                    items: [
                      InfoRow('Type', controller.commissionType.value),
                      InfoRow('Rate', controller.commissionRate.value),
                    ],
                  ),
                ],
              ),
            )),
    );
  }
}
```

### 4.2 View All Recharge History (Admin)

```dart
class AdminRechargeHistoryController extends GetxController {
  final _functions = FirebaseFunctions.instanceFor(region: 'asia-south1');
  
  final RxBool isLoading = false.obs;
  final RxList<RechargeTransaction> transactions = <RechargeTransaction>[].obs;
  final RxString statusFilter = ''.obs;
  final RxString typeFilter = ''.obs;
  String? lastDocId;
  
  final statusOptions = {
    '': 'All Statuses',
    'success': 'Successful',
    'failed': 'Failed',
    'refunded': 'Refunded',
    'pending_verification': 'Pending',
  };
  
  final typeOptions = {
    '': 'All Types',
    'recharge': 'Mobile Recharge',
    'drive_offer': 'Drive Offer',
  };
  
  /// Fetch all recharge history with filters
  Future<void> fetchHistory({bool loadMore = false}) async {
    if (isLoading.value) return;
    
    try {
      isLoading.value = true;
      
      final result = await _functions.httpsCallable('getAdminRechargeHistory').call({
        'limit': 50,
        if (loadMore && lastDocId != null) 'startAfter': lastDocId,
        if (statusFilter.value.isNotEmpty) 'status': statusFilter.value,
        if (typeFilter.value.isNotEmpty) 'type': typeFilter.value,
      });
      
      final data = result.data as Map<String, dynamic>;
      
      if (data['success'] == true) {
        final txList = data['data']['transactions'] as List;
        final newTxs = txList
            .map((json) => RechargeTransaction.fromMap(json as Map<String, dynamic>))
            .toList();
        
        if (loadMore) {
          transactions.addAll(newTxs);
        } else {
          transactions.value = newTxs;
        }
        
        if (newTxs.isNotEmpty) {
          lastDocId = newTxs.last.refid;
        }
      }
      
    } on FirebaseFunctionsException catch (e) {
      AppHelpers.showError(e.message ?? 'Failed to load history');
    } finally {
      isLoading.value = false;
    }
  }
}
```

### 4.3 View Recharge Statistics

```dart
class RechargeStatsController extends GetxController {
  final _functions = FirebaseFunctions.instanceFor(region: 'asia-south1');
  
  final RxBool isLoading = false.obs;
  final RxString selectedPeriod = 'today'.obs;
  
  final RxInt totalRecharges = 0.obs;
  final RxInt totalDriveOffers = 0.obs;
  final RxDouble totalAmount = 0.0.obs;
  final RxDouble totalCashback = 0.0.obs;
  final RxInt successRate = 0.obs;
  final RxInt pendingCount = 0.obs;
  final RxInt failedCount = 0.obs;
  
  final periods = {
    'today': 'Today',
    'week': 'This Week',
    'month': 'This Month',
    'all': 'All Time',
  };
  
  @override
  void onInit() {
    super.onInit();
    fetchStats();
  }
  
  /// Fetch recharge statistics
  Future<void> fetchStats() async {
    try {
      isLoading.value = true;
      
      final result = await _functions.httpsCallable('getRechargeStats').call({
        'period': selectedPeriod.value,
      });
      
      final data = result.data as Map<String, dynamic>;
      
      if (data['success'] == true) {
        final stats = data['data'] as Map<String, dynamic>;
        
        totalRecharges.value = stats['totalRecharges'] ?? 0;
        totalDriveOffers.value = stats['totalDriveOffers'] ?? 0;
        totalAmount.value = (stats['totalAmount'] ?? 0).toDouble();
        totalCashback.value = (stats['totalCashback'] ?? 0).toDouble();
        successRate.value = stats['successRate'] ?? 0;
        pendingCount.value = stats['pendingCount'] ?? 0;
        failedCount.value = stats['failedCount'] ?? 0;
      }
      
    } on FirebaseFunctionsException catch (e) {
      AppHelpers.showError(e.message ?? 'Failed to fetch statistics');
    } finally {
      isLoading.value = false;
    }
  }
}
```

### 4.4 Retry Failed Recharge

```dart
class AdminRechargeDetailsController extends GetxController {
  final _functions = FirebaseFunctions.instanceFor(region: 'asia-south1');
  
  final RxBool isLoading = false.obs;
  
  /// Retry a pending/failed recharge
  Future<void> retryRecharge(String refid) async {
    try {
      isLoading.value = true;
      
      final result = await _functions.httpsCallable('adminRetryRecharge').call({
        'refid': refid,
      });
      
      final data = result.data as Map<String, dynamic>;
      
      if (data['success'] == true) {
        final status = data['data']['status'];
        final message = data['data']['message'];
        
        if (status == 'success') {
          AppHelpers.showSuccess('Recharge completed successfully!');
        } else if (status == 'refunded') {
          AppHelpers.showInfo('Recharge failed and refunded');
        } else {
          AppHelpers.showInfo(message ?? 'Status: $status');
        }
        
        // Refresh transaction details
        // fetchTransactionDetails(refid);
      } else {
        AppHelpers.showError(data['message'] ?? 'Retry failed');
      }
      
    } on FirebaseFunctionsException catch (e) {
      AppHelpers.showError(e.message ?? 'Retry failed');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Check ECARE status for a transaction
  Future<void> checkEcareStatus(String refid) async {
    try {
      isLoading.value = true;
      
      final result = await _functions.httpsCallable('adminRechargeStatus').call({
        'refid': refid,
      });
      
      final data = result.data as Map<String, dynamic>;
      
      if (data['success'] == true) {
        final statusData = data['data'] as Map<String, dynamic>;
        final status = statusData['RECHARGE_STATUS'];
        final message = statusData['MESSAGE'];
        
        Get.dialog(
          AlertDialog(
            title: const Text('ECARE Status'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: $status'),
                const SizedBox(height: 8),
                Text('Message: $message'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
      
    } on FirebaseFunctionsException catch (e) {
      AppHelpers.showError(e.message ?? 'Failed to check status');
    } finally {
      isLoading.value = false;
    }
  }
}
```

### 4.5 Refresh Drive Offer Cache

```dart
class DriveOfferManagementController extends GetxController {
  final _functions = FirebaseFunctions.instanceFor(region: 'asia-south1');
  
  final RxBool isRefreshing = false.obs;
  
  /// Force refresh drive offer cache from ECARE API
  Future<void> refreshCache() async {
    try {
      isRefreshing.value = true;
      
      final result = await _functions.httpsCallable('refreshDriveOfferCache').call();
      
      final data = result.data as Map<String, dynamic>;
      
      if (data['success'] == true) {
        final totalOffers = data['data']['totalOffers'];
        AppHelpers.showSuccess('Cache refreshed! $totalOffers offers loaded.');
      }
      
    } on FirebaseFunctionsException catch (e) {
      AppHelpers.showError(e.message ?? 'Failed to refresh cache');
    } finally {
      isRefreshing.value = false;
    }
  }
}
```

---

## 5. Testing Guide

### 5.1 Test ECARE API Connection

**Step 1: Check Balance (Admin only)**

```dart
// In Firebase Console or Flutter app
final result = await functions.httpsCallable('getEcareBalance').call();
print(result.data);
```

**Expected Output:**
```json
{
  "success": true,
  "message": "Balance retrieved",
  "data": {
    "STATUS": "OK",
    "MAIN_BALANCE": "10000.00",
    "STOCK_BALANCE": "5000.00",
    "COMMISSION_TYPE": "PERCENTAGE",
    "COMMISSION_RATE": "2.5",
    "MESSAGE": "Balance Check Successful"
  }
}
```

**Step 2: Fetch Drive Offers**

```dart
final result = await functions.httpsCallable('getDriveOffers').call({
  'operator': '7', // Grameenphone
});
print('Total offers: ${result.data['data']['totalOffers']}');
```

**Step 3: Test Recharge (Use test phone number)**

```dart
final result = await functions.httpsCallable('initiateRecharge').call({
  'phone': '01700000000', // Replace with actual test number
  'operator': '7',
  'numberType': '1',
  'amount': 20, // Minimum amount
  'type': 'recharge',
});
print(result.data);
```

### 5.2 Error Scenarios to Test

| Scenario | Expected Behavior |
|----------|-------------------|
| Invalid phone format | Error: "Invalid phone number. Must be 11 digits starting with 01." |
| Amount < 20৳ | Error: "Recharge amount must be between ৳20 and ৳5,000" |
| Amount not divisible by 10 | Error: "Recharge amount must be a round figure (ending in 0)" |
| Insufficient wallet | Error: "Insufficient wallet balance" |
| Daily limit exceeded | Error: "Daily limit reached (20 recharges per day)" |
| ECARE API unreachable | Status: "refunded", Message: "Recharge service is temporarily unavailable. Your wallet has been refunded." |

### 5.3 Monitoring Transactions

**Firestore Console:**
1. Go to Firebase Console → Firestore Database
2. Navigate to `mobile_recharge` collection
3. Check transaction documents for status updates

**Transaction Statuses:**
- `initiated` → Wallet debited, ECARE not yet called
- `submitted` → ECARE accepted request, polling in progress
- `processing` → ECARE is processing the recharge
- `success` → Recharge completed, cashback credited
- `failed` → ECARE rejected, wallet refunded
- `refunded` → User refunded due to failure
- `pending_verification` → Max polls exceeded, needs manual check

---

## 6. Troubleshooting

### 6.1 Common Issues

**Issue:** "ECARE API credentials not configured"

**Solution:**
```bash
# Set credentials
firebase functions:secrets:set ECARE_ACCESS_ID
firebase functions:secrets:set ECARE_ACCESS_PASS

# Redeploy
firebase deploy --only functions
```

---

**Issue:** "Database index required" error

**Solution:**
1. Copy the URL from the error message
2. Open it in a browser
3. Click "Create Index"
4. Wait 2-5 minutes for index to build

---

**Issue:** Drive offers list is empty

**Solution:**
```dart
// Admin: Force refresh cache
await functions.httpsCallable('refreshDriveOfferCache').call();
```

---

**Issue:** Recharge stuck in "pending_verification"

**Solution (Admin):**
```dart
// Check ECARE status
await functions.httpsCallable('adminRechargeStatus').call({
  'refid': 'SHR_1708089600000_a1b2c3',
});

// Or retry
await functions.httpsCallable('adminRetryRecharge').call({
  'refid': 'SHR_1708089600000_a1b2c3',
});
```

---

**Issue:** "Quota exceeded" during deployment

**Solution:**
```bash
# Wait 60 seconds and retry
firebase deploy --only functions
```

---

### 6.2 Debugging Tips

**Enable Function Logs:**
```bash
# View real-time logs
firebase functions:log --only initiateRecharge

# View logs for specific time
firebase functions:log --since 1h
```

**Check Function Details:**
```bash
# List all functions
firebase functions:list

# Get function details
firebase functions:config:get
```

**Test in Firebase Console:**
1. Go to Firebase Console → Functions
2. Click on a function (e.g., `initiate Recharge`)
3. Click "Test function" tab
4. Enter test data JSON
5. Click "Test the function"

---

## 7. API Reference Quick Guide

### 7.1 Operator Codes

| Operator | Code |
|----------|------|
| Grameenphone | `7` or `3` |
| Banglalink | `4` or `9` |
| Robi | `8` |
| Airtel | `6` |
| Teletalk | `5` |

### 7.2 Number Type Codes

| Type | Code |
|------|------|
| Prepaid | `1` |
| Postpaid | `2` |
| Skitto | `3` |
| PowerLoad | `4` |

### 7.3 Offer Type Codes

| Type | Code |
|------|------|
| Internet | `IN` |
| Minutes | `MN` |
| Bundle | `BD` |

### 7.4 Transaction Status Values

| Status | Description |
|--------|-------------|
| `initiated` | Wallet debited, API call pending |
| `submitted` | ECARE accepted, polling status |
| `processing` | Recharge in progress at operator |
| `success` | Completed, cashback credited |
| `failed` | ECARE failed |
| `refunded` | User refunded |
| `pending_verification` | Needs admin check |

### 7.5 Business Rules Summary

| Rule | Value |
|------|-------|
| Min recharge amount | ৳20 |
| Max recharge amount | ৳5,000 |
| Amount increment | ৳10 (must be divisible by 10) |
| Cashback percentage | 1.5% |
| Max daily recharges | 20 per user |
| Max daily drive offers | 10 per user |
| Offer cache TTL | 1 hour |
| Status poll attempts | 10 |
| Poll delays | 5s, 10s, 15s, 30s, 60s... |

---

## 8. Production Checklist

Before going live:

- [ ] ECARE credentials configured via Firebase secrets
- [ ] All Firestore indexes created
- [ ] Functions deployed successfully
- [ ] ECARE balance checked (sufficient funds)
- [ ] Test recharge completed successfully
- [ ] Drive offer cache populated
- [ ] User wallet has test balance
- [ ] Error handling tested
- [ ] Daily limits tested
- [ ] Cashback calculation verified
- [ ] Refund mechanism tested
- [ ] Admin functions tested (balance, history, retry)
- [ ] Transaction history displays correctly
- [ ] Status updates working in real-time
- [ ] Audit logs recording properly

---

## 9. Support & Contacts

**ECARE Technology:**
- Email: info@ect.com.bd
- Phone: +88 01718-840256
- Website: www.ect.com.bd

**Firebase Support:**
- Console: https://console.firebase.google.com
- Documentation: https://firebase.google.com/docs/functions

**Project Documentation:**
- Full API docs: `documents/mobileRecharge/Ecare_Topup_API_20_11_2021.md`
- Database schema: `documents/appArchitechture/firestore_database_structure.md`
- Functions source: `functions/src/features/mobile-recharge/`

---

**Document Version:** 1.0  
**Last Updated:** February 16, 2026  
**Next Review:** March 2026
