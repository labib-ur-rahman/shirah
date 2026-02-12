# 🏗️ SHIRAH Architecture - Quick Reference

```
┌─────────────────────────────────────────────────────────────────────┐
│                     SHIRAH FLUTTER APP                              │
│                    (Your Mobile Application)                         │
└────────────┬────────────────────────────────────────────────────────┘
             │
             ├─► 📱 UI Layer (features/)
             │   └─► Screens, Widgets, Views
             │
             ├─► 🎮 Controller Layer (GetX)
             │   ├─► AuthController
             │   ├─► UserController
             │   ├─► WalletController
             │   └─► RewardController
             │
             ├─► 📂 Repository Layer (data/repositories/)
             │   ├─► AuthRepository ──────┐
             │   ├─► UserRepository        │
             │   ├─► WalletRepository      │  Calls Cloud Functions
             │   └─► RewardRepository ─────┤
             │                             │
             └─► 🔧 Services              │
                 ├─► FirebaseService       │
                 ├─► CloudFunctionsService ◄┘
                 ├─► ConnectivityService
                 └─► LoggerService
                           │
                           │ HTTPS Callable
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│            FIREBASE CLOUD FUNCTIONS (asia-south1)                   │
│                    35 Deployed Functions                            │
└─────────────┬───────────────────────────────────────────────────────┘
              │
              ├─► 🔐 Authentication (4)
              │   ├─ verifyUserProfile
              │   ├─ subscribeUser
              │   ├─ checkAuthStatus
              │   └─ onUserDeleted (trigger)
              │
              ├─► 👤 User Management (4)
              │   ├─ createUser ✅ (atomically creates all docs)
              │   ├─ completeGoogleSignIn ✅
              │   ├─ getUserProfile
              │   └─ updateUserProfile
              │
              ├─► 💰 Wallet (3)
              │   ├─ requestWithdrawal
              │   ├─ getMyWalletTransactions
              │   └─ getMyWithdrawalRequests
              │
              ├─► 🎁 Rewards (4)
              │   ├─ recordAdView ✅
              │   ├─ convertRewardPoints ✅
              │   ├─ getStreakInfo
              │   └─ getMyRewardTransactions
              │
              ├─► 🔑 Permissions (5)
              │   ├─ getMyPermissions
              │   ├─ getUserPermissions
              │   ├─ grantUserPermissions
              │   ├─ revokeUserPermissions
              │   └─ changeUserRole
              │
              ├─► 👮 Admin (12)
              │   ├─ suspendUser / banUser / unbanUser
              │   ├─ setUserRiskLevel
              │   ├─ adminCreditWallet / adminCreditRewardPoints
              │   ├─ adminLockWallet / adminUnlockWallet
              │   ├─ approveWithdrawal / rejectWithdrawal
              │   ├─ getPendingWithdrawals
              │   ├─ getAdminUserDetails
              │   └─ searchUsers
              │
              └─► ⚙️ Configuration (3)
                  ├─ seedConfigurations ✅ (run once)
                  ├─ updateAppConfig
                  └─ getAppConfigAdmin
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    CLOUD FIRESTORE DATABASE                         │
└─────────────┬───────────────────────────────────────────────────────┘
              │
              ├─► 📁 users/{uid}
              │   └─ Core user profile (identity, wallet, status)
              │
              ├─► 📁 invite_codes/{code}
              │   └─ Invite code uniqueness index
              │
              ├─► 📁 user_uplines/{uid}
              │   └─ 15-level upline chain cache
              │
              ├─► 📁 user_relations/{autoId}
              │   └─ Network graph edges
              │
              ├─► 📁 user_network_stats/{uid}
              │   └─ Aggregated network counters
              │
              ├─► 📁 wallet_transactions/{autoId}
              │   └─ BDT transaction ledger
              │
              ├─► 📁 reward_transactions/{autoId}
              │   └─ Reward points ledger
              │
              ├─► 📁 withdrawal_requests/{autoId}
              │   └─ Withdrawal queue
              │
              ├─► 📁 streak_data/{uid}
              │   └─ Daily streak tracking
              │
              ├─► 📁 ad_view_logs/{autoId}
              │   └─ Ad view history
              │
              ├─► 📁 admin_permissions/{adminUid}
              │   └─ Admin RBAC
              │
              ├─► 📁 audit_logs/{autoId}
              │   └─ System audit trail
              │
              └─► 📁 configurations/app_settings
                  └─ Dynamic business rules ✅ (seed required)
```

---

## 🔄 Data Flow Examples

### 1. User Signup (Email/Password)
```
Flutter App
    ↓
AuthRepository.signUpWithEmailPassword()
    ↓
CloudFunctionsService.createUser()
    ↓ HTTPS Callable
Cloud Function: createUser
    ├─ Validate invite code
    ├─ Create Firebase Auth user
    ├─ Build 15-level upline chain
    ├─ Create user document
    ├─ Create invite_codes document
    ├─ Create user_uplines document
    ├─ Create user_relations documents
    ├─ Create user_network_stats document
    ├─ Update parent's network stats
    └─ Create audit log
    ↓
Return success
    ↓
Flutter signs in with credentials
    ↓
AuthRepository._updateLastLogin() ✅ (non-blocking)
    ↓ Direct Firestore update
Update users/{uid}/meta.lastLoginAt
    ↓
Fetch user profile
    ↓
Return to app
```

### 2. Watch Ad & Earn Points
```
Flutter App
    ↓
RewardController.recordAdView()
    ↓
CloudFunctionsService.recordAdView()
    ↓ HTTPS Callable
Cloud Function: recordAdView
    ├─ Validate user status
    ├─ Check daily ad limit (max 20)
    ├─ Calculate streak multiplier
    ├─ Calculate points (30 × multiplier)
    ├─ Create ad_view_logs document
    ├─ Update streak_data document
    ├─ Create reward_transactions document
    ├─ Update user wallet
    └─ Create audit log
    ↓
Return { success, pointsEarned, newBalance }
    ↓
RewardController updates UI
```

### 3. Convert Points to BDT
```
Flutter App
    ↓
WalletController.convertPoints()
    ↓
CloudFunctionsService.convertRewardPoints()
    ↓ HTTPS Callable
Cloud Function: convertRewardPoints
    ├─ Validate user status
    ├─ Check minimum (100 pts)
    ├─ Check daily limit (2 conversions)
    ├─ Calculate amount (100 pts = 1 BDT)
    ├─ Calculate fee (5%)
    ├─ Debit reward points
    ├─ Credit wallet balance (BDT)
    ├─ Create reward_transactions document
    ├─ Create wallet_transactions document
    └─ Create audit log
    ↓
Return { success, amount, fee, newBalance }
    ↓
WalletController updates UI
```

### 4. Request Withdrawal
```
Flutter App
    ↓
WalletController.requestWithdrawal()
    ↓
CloudFunctionsService.requestWithdrawal()
    ↓ HTTPS Callable
Cloud Function: requestWithdrawal
    ├─ Validate user status
    ├─ Check verification/subscription
    ├─ Check wallet locked status
    ├─ Validate balance
    ├─ Calculate fee
    ├─ Create withdrawal_requests document
    ├─ Update user wallet (lock amount)
    └─ Create audit log
    ↓
Return { success, requestId, fee }
    ↓
Admin approves/rejects later
    ↓ Admin calls approveWithdrawal()
Cloud Function: approveWithdrawal
    ├─ Debit wallet balance
    ├─ Create wallet_transactions document
    ├─ Update withdrawal status
    ├─ Notify user
    └─ Create audit log
```

---

## 🔐 Security Layers

### Layer 1: Firebase Authentication
- ✅ Every Cloud Function call requires auth token
- ✅ `request.auth.uid` identifies the user

### Layer 2: Cloud Functions Validation
- ✅ Validates user status (active, not banned)
- ✅ Checks verific permissions (canWithdraw, etc.)
- ✅ Rate limiting (daily ads, conversions)

### Layer 3: Firestore Rules
- ✅ Users can only read their own documents
- ✅ All writes go through Cloud Functions
- ✅ Direct writes are denied

### Layer 4: RBAC (Role-Based Access Control)
- ✅ Admin functions check role
- ✅ Permission-based operations
- ✅ Audit logging for accountability

---

## 📊 Performance Optimizations

### 1. Progressive Loading
- ✅ Parent data loads immediately
- ✅ Child data loads in parallel
- ✅ Shimmer while loading

### 2. Caching
- ✅ Upline chain cached in `user_uplines`
- ✅ Network stats cached per user
- ✅ Dynamic config cached in-memory

### 3. Batched Operations
- ✅ Firestore transactions for atomicity
- ✅ Batch writes for multiple documents
- ✅ Parallel reads where possible

### 4. Region Optimization
- ✅ Functions in asia-south1 (Mumbai)
- ✅ ~15ms latency to Bangladesh
- ✅ Optimal for target audience

---

## 🎯 Key Design Decisions

### Why Cloud Functions?
1. **Atomicity** - All-or-nothing operations
2. **Security** - Server-side validation
3. **Consistency** - Single source of truth
4. **Auditability** - Complete operation logs
5. **Scalability** - Auto-scales with load

### Why Repository Pattern?
1. **Separation** - UI doesn't know about Firebase
2. **Testability** - Easy to mock repositories
3. **Maintainability** - Changes isolated to repos
4. **Flexibility** - Can swap backend easily

### Why GetX?
1. **Performance** - Minimal rebuilds
2. **Simplicity** - Easy state management
3. **Dependency Injection** - Clean architecture
4. **Routing** - Built-in navigation

---

## 🚀 Development Workflow

### 1. Add New Feature
```
1. Define Cloud Function (if needed)
   ├─ functions/src/features/[feature]/
   └─ Export in functions/src/index.ts

2. Deploy Cloud Function
   └─ firebase deploy --only functions:[functionName]

3. Add method to CloudFunctionsService
   └─ lib/core/services/cloud_functions_service.dart

4. Create/Update Repository
   └─ lib/data/repositories/[feature]_repository.dart

5. Create/Update Controller
   └─ lib/features/[feature]/controllers/

6. Build UI
   └─ lib/features/[feature]/views/
```

### 2. Test Locally
```bash
# Run Firebase emulators
cd functions
npm run serve

# Update Flutter to use emulator
# (Optional - for local testing)
```

### 3. Deploy to Production
```bash
# Deploy functions
cd functions
npm run deploy

# Deploy Flutter app
flutter build apk --release
```

---

## 📝 Naming Conventions

### Cloud Functions
- **Callable:** `camelCase` (e.g., `createUser`, `recordAdView`)
- **Triggers:** `on[Event][Resource]` (e.g., `onUserDeleted`)

### Flutter
- **Services:** `[Name]Service` (e.g., `CloudFunctionsService`)
- **Repositories:** `[Feature]Repository` (e.g., `WalletRepository`)
- **Controllers:** `[Feature]Controller` (e.g., `AuthController`)
- **Models:** `[Name]Model` (e.g., `UserModel`)

### Firestore
- **Collections:** `snake_case` (e.g., `invite_codes`)
- **Documents:** Varies by collection
- **Fields:** `camelCase` (e.g., `inviteCode`)

---

*This architecture ensures scalability, security, and maintainability while following Flutter and Firebase best practices.*
