# 🚀 Quick Start Guide - SHIRAH Development

> **Status:** ✅ Everything is set up and ready to go!

---

## ⚡ Start Developing NOW

### Step 1: Seed Configuration (5 minutes) ✅ REQUIRED

Run this **ONCE** to initialize app settings:

```dart
// In your Flutter app, create a temporary button or run in main():
import 'package:shirah/core/services/cloud_functions_service.dart';

final cloudFunctions = CloudFunctionsService.instance;
try {
  final result = await cloudFunctions.seedConfigurations();
  print('✅ Configurations seeded: $result');
} catch (e) {
  print('❌ Error: $e');
}
```

**Or run from Firebase Console:**
1. Go to: https://console.firebase.google.com/project/shirahsoft/functions
2. Find `seedConfigurations` function
3. Click **Test** tab
4. Leave payload empty `{}`
5. Click **Run** button

---

### Step 2: Create First Super Admin (10 minutes) ✅ REQUIRED

```bash
cd functions
npm run create-super-admin
```

Follow the prompts:
- Enter email
- Enter password (min 8 chars)
- Enter first name
- Enter last name
- Enter Bangladesh phone (01XXXXXXXXX)

**Result:** First admin user created with invite code `SSHIRAHL`

---

### Step 3: Test User Signup (2 minutes)

```dart
import 'package:shirah/data/repositories/authentication/auth_repository.dart';

final authRepo = AuthRepository();

// Test signup
try {
  final result = await authRepo.signUpWithEmailPassword(
    email: 'test@example.com',
    password: 'Test123456!',
    firstName: 'Test',
    lastName: 'User',
    phoneNumber: '01712345678',
    inviteCode: 'SSHIRAHL', // Use super admin's code
  );
  
  print('✅ Signup successful!');
  print('User: ${result['user'].uid}');
} catch (e) {
  print('❌ Error: $e');
}
```

---

## 🎯 Common Operations

### Access Cloud Functions

```dart
import 'package:shirah/core/services/cloud_functions_service.dart';

final cf = CloudFunctionsService.instance;
```

### Record Ad View

```dart
final result = await cf.recordAdView(
  adType: 'video',
  deviceId: 'device_123',
);

print('Points earned: ${result['data']['pointsEarned']}');
```

### Convert Points to BDT

```dart
final result = await cf.convertRewardPoints(
  points: 1000, // 1000 points = 10 BDT
);

print('Converted: ${result['data']['amount']} BDT');
```

### Request Withdrawal

```dart
final result = await cf.requestWithdrawal(
  amount: 100.0,
  paymentMethod: 'bkash',
  paymentDetails: {
    'accountNumber': '01712345678',
    'accountName': 'John Doe',
  },
);

print('Request ID: ${result['data']['requestId']}');
```

### Get User Profile

```dart
final result = await cf.getUserProfile();
print('Balance: ${result['data']['wallet']['balanceBDT']} BDT');
print('Points: ${result['data']['wallet']['rewardPoints']}');
```

---

## 🏗️ Project Structure Quick Reference

```
lib/
├── core/
│   ├── services/
│   │   ├── cloud_functions_service.dart  ← ✅ Use this!
│   │   ├── firebase_service.dart
│   │   └── logger_service.dart
│   └── bindings/
│       └── initial_binding.dart           ← Services registered here
│
├── data/
│   ├── repositories/
│   │   ├── authentication/
│   │   │   └── auth_repository.dart       ← Auth operations
│   │   ├── user_repository.dart           ← User CRUD
│   │   ├── wallet_repository.dart         ← Wallet operations
│   │   └── reward_repository.dart         ← Reward operations
│   └── models/                            ← Data models
│
└── features/
    ├── authentication/                    ← Login/signup UI
    ├── wallet/                            ← Wallet UI
    ├── rewards/                           ← Rewards UI
    └── profile/                           ← Profile UI
```

---

## 🔧 Development Tips

### 1. Always Use CloudFunctionsService

```dart
// ✅ CORRECT
final cf = CloudFunctionsService.instance;
await cf.createUser(...);

// ❌ WRONG
FirebaseFunctions.instance.httpsCallable('createUser').call(...);
```

### 2. Never Write to Firestore Directly

```dart
// ❌ WRONG - Security rules will block this
FirebaseFirestore.instance
  .collection('users')
  .doc(uid)
  .update({'wallet.balanceBDT': 1000});

// ✅ CORRECT - Use Cloud Functions
await CloudFunctionsService.instance.adminCreditWallet(
  targetUid: uid,
  amount: 1000,
  reason: 'Bonus credit',
);
```

### 3. Handle Errors Properly

```dart
try {
  final result = await cf.recordAdView(...);
  // Handle success
} on String catch (errorMessage) {
  // Cloud Functions throw String errors
  AppSnackBar.errorSnackBar(
    title: AppStrings.error,
    message: errorMessage,
  );
} catch (e) {
  // Unknown errors
  LoggerService.error('Unexpected error', e);
  AppSnackBar.errorSnackBar(
    title: AppStrings.error,
    message: AppStrings.somethingWentWrong,
  );
}
```

### 4. Use Proper Loading States

```dart
// Show global loading
EasyLoading.show(status: AppStrings.loading);

try {
  final result = await cf.someFunction();
  EasyLoading.dismiss();
  
  // Show success feedback
  AppSnackBar.successSnackBar(
    title: AppStrings.success,
    message: AppStrings.operationComplete,
  );
} catch (e) {
  EasyLoading.dismiss();
  AppSnackBar.errorSnackBar(...);
}
```

---

## 📱 Testing Checklist

### User Authentication
- [ ] Email/password signup with invite code
- [ ] Email/password login
- [ ] Google Sign-In (new user)
- [ ] Google Sign-In (existing user)
- [ ] Logout
- [ ] Password reset

### Wallet Operations
- [ ] View wallet balance
- [ ] View transaction history
- [ ] Request withdrawal
- [ ] View withdrawal requests

### Reward System
- [ ] Watch ad and earn points
- [ ] View streak information
- [ ] Convert points to BDT
- [ ] View reward transaction history

### Profile
- [ ] View profile
- [ ] Update profile (name, phone, avatar)
- [ ] View network information

---

## 🐛 Troubleshooting

### "User not found" after signup

**Cause:** Firestore document not created  
**Solution:** Check Cloud Function logs in Firebase Console

### "Insufficient permissions"

**Cause:** User not verified or subscription inactive  
**Solution:** 
```dart
await cf.verifyUserProfile(paymentReference: 'ref_123');
```

### "Invalid invite code"

**Cause:** Invite code doesn't exist or malformed  
**Solution:** 
- Use uppercase: `SADMIN01` ✅ not `sadmin01` ❌
- Format: `S[6_chars]L` (e.g., `SA7K9Q2L`)

### Cloud Function timeout

**Cause:** Network issue or function cold start  
**Solution:**
- Increase timeout in CloudFunctionsService
- Check internet connection
- Wait ~30 seconds for cold start

---

## 📊 Monitor Your App

### Firebase Console
- **Functions:** https://console.firebase.google.com/project/shirahsoft/functions
- **Firestore:** https://console.firebase.google.com/project/shirahsoft/firestore
- **Authentication:** https://console.firebase.google.com/project/shirahsoft/authentication

### Check Function Logs
```bash
firebase functions:log --only [functionName]
```

### Check Function Metrics
1. Go to Functions in Firebase Console
2. Click on function name
3. View: Invocations, Execution time, Memory usage, Errors

---

## 🎓 Learning Resources

### Flutter + Firebase
- [Official Firebase for Flutter](https://firebase.flutter.dev/)
- [GetX Documentation](https://pub.dev/packages/get)
- [Cloud Functions Guide](https://firebase.google.com/docs/functions)

### SHIRAH Documentation
- [INTEGRATION_COMPLETE.md](INTEGRATION_COMPLETE.md) - Full integration guide
- [ARCHITECTURE_OVERVIEW.md](ARCHITECTURE_OVERVIEW.md) - System architecture
- [documents/](documents/) - Business logic & system docs

---

## 💡 Pro Tips

1. **Use Logger Service** for debugging:
   ```dart
   LoggerService.info('User logged in: $uid');
   LoggerService.error('Error occurred', exception);
   ```

2. **Check Function Responses** in logs:
   ```dart
   final result = await cf.someFunction();
   LoggerService.debug('Response: $result');
   ```

3. **Test in Emulator First** (optional):
   ```bash
   cd functions
   npm run serve
   ```

4. **Keep Cloud Functions Updated**:
   ```bash
   cd functions
   npm run deploy
   ```

5. **Monitor Costs** in Firebase Console billing section

---

## 🆘 Need Help?

### Error Messages
- Check Firebase Console → Functions → Logs
- Check Flutter console output
- Use `LoggerService.error()` for stack traces

### Common Issues
1. **Authentication errors** → Check Firebase Auth settings
2. **Permission denied** → Check Firestore rules
3. **Function not found** → Verify function deployed
4. **Timeout** → Check network connection

### Documentation
- [Firebase Documentation](https://firebase.google.com/docs)
- [Flutter Documentation](https://docs.flutter.dev/)
- Project docs in [documents/](documents/) folder

---

## ✅ You're All Set!

Your SHIRAH app is now fully integrated and ready for development. All Cloud Functions are deployed, Flutter services are configured, and the architecture is production-ready.

**Next:** Start building features using the CloudFunctionsService! 🚀

---

*Quick Start Guide - Updated February 11, 2026*
