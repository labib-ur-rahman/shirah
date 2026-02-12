# 🎯 AppHelper Quick Reference Guide

## 📌 Import Statement

```dart
import 'package:shirah/core/utils/helpers/app_helper.dart';
```

---

## 🎨 Theme & Colors (REACTIVE)

### Use in Obx for Automatic Updates

```dart
// Background colors
Obx(() => Container(color: AppHelper.backgroundColor))
Obx(() => Container(color: AppHelper.cardColor))

// Text colors
Obx(() => Text('Hello', style: TextStyle(color: AppHelper.textColor)))
Obx(() => Text('Subtitle', style: TextStyle(color: AppHelper.secondaryTextColor)))

// Border & Shadow
Obx(() => Container(
  decoration: BoxDecoration(
    border: Border.all(color: AppHelper.borderColor),
    boxShadow: [BoxShadow(color: AppHelper.shadowColor)],
  ),
))

// Boolean checks
Obx(() {
  if (AppHelper.isDarkMode) {
    return DarkWidget();
  }
  return LightWidget();
})
```

---

## 🌍 Language & Locale (REACTIVE)

```dart
// Boolean checks
Obx(() {
  if (AppHelper.isBangla) {
    return Text('বাংলা');
  }
  return Text('English');
})

// Greeting (time-based + localized)
Obx(() => Text(AppHelper.getGreeting()))
// Returns: 'Good Morning' or 'সুপ্রভাত'

// Current language code
Obx(() => Text('Language: ${AppHelper.currentLanguage}'))
// Returns: 'en' or 'bn'
```

---

## 🔔 UI Feedback

```dart
// Success message
AppHelper.showSuccess('Profile updated!');

// Error message
AppHelper.showError('Invalid credentials');

// Info message
AppHelper.showInfo('Please verify your email');

// Loading
AppHelper.showLoading('Processing...');
await doWork();
AppHelper.dismissLoading();

// Simple snackbar
AppHelper.showSnackBar('Item added to cart');

// Alert dialog
AppHelper.showAlert('Error', 'Something went wrong');

// Confirmation dialog
AppHelper.showConfirmDialog(
  'Delete Account',
  'Are you sure you want to delete your account?',
  onConfirm: () async {
    await deleteAccount();
    AppHelper.showSuccess('Account deleted');
  },
  confirmText: 'Delete',
  cancelText: 'Cancel',
);
```

---

## 📱 Screen & Device

```dart
// Screen dimensions
final width = AppHelper.screenWidth;  // e.g., 375.0
final height = AppHelper.screenHeight;  // e.g., 812.0
final size = AppHelper.screenSize;  // Size(375.0, 812.0)

// Safe areas
final statusBarHeight = AppHelper.statusBarHeight;  // e.g., 44.0
final bottomPadding = AppHelper.bottomPadding;  // e.g., 34.0

// Orientation
if (AppHelper.isLandscape) {
  // Show wide layout
} else if (AppHelper.isPortrait) {
  // Show tall layout
}

// Keyboard
if (AppHelper.isKeyboardVisible) {
  final keyboardHeight = AppHelper.keyboardHeight;
}
AppHelper.hideKeyboard();
```

---

## 📅 Date & Time

```dart
// Format date
final date = AppHelper.formatDate(DateTime.now());
// Returns: '11 Feb 2026'

final customDate = AppHelper.formatDate(
  DateTime.now(),
  format: 'yyyy-MM-dd',
);
// Returns: '2026-02-11'

// Date with time
final dateTime = AppHelper.formatDateTime(DateTime.now());
// Returns: '11 Feb 2026 15:30'

// Time ago
final postTime = DateTime.now().subtract(Duration(hours: 2));
final timeAgo = AppHelper.timeAgo(postTime);
// Returns: '2 hours ago'
```

---

## 📝 String Utilities

```dart
// Truncate
final truncated = AppHelper.truncateText('Hello World', 5);
// Returns: 'Hello...'

// Capitalize
final capitalized = AppHelper.capitalize('hello world');
// Returns: 'Hello World'

// Email validation
if (AppHelper.isEmail('test@example.com')) {
  // Valid email
}

// Phone validation (Bangladesh)
if (AppHelper.isPhoneNumber('01712345678')) {
  // Valid phone
}

// Null or empty check
if (AppHelper.isNullOrEmpty(value)) {
  // Handle empty
}
```

---

## 💰 Numbers & Currency

```dart
// Format with commas
final formatted = AppHelper.formatNumber(1234567);
// Returns: '1,234,567'

// Currency (BDT)
final price = AppHelper.formatCurrency(1234.56);
// Returns: '৳1,234.56'

// Percentage
final percent = AppHelper.formatPercentage(0.1234);
// Returns: '12.34%'

// Abbreviate
final abbreviated = AppHelper.abbreviateNumber(1234567);
// Returns: '1.2M'
```

---

## ✅ Form Validation

```dart
// Email
String? emailError = AppHelper.validateEmail(emailController.text);
if (emailError != null) {
  // Show error
}

// Phone
String? phoneError = AppHelper.validatePhone(phoneController.text);

// Password
String? passwordError = AppHelper.validatePassword(
  passwordController.text,
  minLength: 8,
);

// Use in TextFormField
TextFormField(
  validator: (value) => AppHelper.validateEmail(value),
  decoration: InputDecoration(labelText: 'Email'),
)
```

---

## 📋 List Utilities

```dart
// Remove duplicates
final unique = AppHelper.removeDuplicates([1, 2, 2, 3]);
// Returns: [1, 2, 3]

// Chunk into smaller lists
final chunked = AppHelper.chunkList([1, 2, 3, 4, 5], 2);
// Returns: [[1, 2], [3, 4], [5]]

// Wrap widgets in rows
final wrapped = AppHelper.wrapWidgets(
  [Widget1(), Widget2(), Widget3()],
  2, // 2 widgets per row
);
// Returns: [Row([Widget1, Widget2]), Row([Widget3])]
```

---

## 🔧 Device Utils (Use AppDeviceUtils)

```dart
import 'package:shirah/core/utils/device/device_utility.dart';

// Haptic feedback
AppDeviceUtils.lightHaptic();
AppDeviceUtils.mediumHaptic();
AppDeviceUtils.heavyHaptic();
AppDeviceUtils.vibrate();

// Platform detection
if (AppDeviceUtils.isAndroid) {
  // Android code
} else if (AppDeviceUtils.isIOS) {
  // iOS code
}

// Network check
if (await AppDeviceUtils.hasInternetConnection) {
  // Make API call
}

// Launch utilities
await AppDeviceUtils.launchURL('https://shirah.com');
await AppDeviceUtils.launchEmail('support@shirah.com');
await AppDeviceUtils.launchPhone('01712345678');
await AppDeviceUtils.launchSMS('01712345678', message: 'Hello!');
```

---

## 🎯 Common Patterns

### Theme-Aware Widget

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        color: AppHelper.cardColor,
        child: Text(
          'Hello',
          style: TextStyle(color: AppHelper.textColor),
        ),
      ),
    );
  }
}
```

### Multi-Language Support

```dart
class GreetingWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        children: [
          Text(AppHelper.getGreeting()),
          Text(
            AppHelper.isBangla
                ? 'আপনাকে স্বাগতম'
                : 'Welcome',
          ),
        ],
      ),
    );
  }
}
```

### Form with Validation

```dart
class LoginForm extends StatelessWidget {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void submit() {
    final emailError = AppHelper.validateEmail(emailController.text);
    final passwordError = AppHelper.validatePassword(passwordController.text);

    if (emailError != null) {
      AppHelper.showError(emailError);
      return;
    }
    if (passwordError != null) {
      AppHelper.showError(passwordError);
      return;
    }

    AppHelper.showLoading('Logging in...');
    // Do login
    AppHelper.dismissLoading();
    AppHelper.showSuccess('Login successful!');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: emailController,
          validator: (value) => AppHelper.validateEmail(value),
        ),
        TextFormField(
          controller: passwordController,
          validator: (value) => AppHelper.validatePassword(value),
          obscureText: true,
        ),
        ElevatedButton(
          onPressed: submit,
          child: Text('Login'),
        ),
      ],
    );
  }
}
```

---

## 💡 Pro Tips

1. **Always use Obx() for reactive properties**
   ```dart
   // ✅ Correct
   Obx(() => Text(AppHelper.isDarkMode ? 'Dark' : 'Light'))
   
   // ❌ Wrong (won't update on theme change)
   Text(AppHelper.isDarkMode ? 'Dark' : 'Light')
   ```

2. **Use helper properties instead of manual checks**
   ```dart
   // ✅ Correct
   color: AppHelper.cardColor
   
   // ❌ Wrong (more code, not reactive)
   color: Get.isDarkMode ? Color(0xFF1E1E2E) : Colors.white
   ```

3. **Leverage validation helpers**
   ```dart
   // ✅ Correct
   validator: (value) => AppHelper.validateEmail(value)
   
   // ❌ Wrong (custom regex, error-prone)
   validator: (value) {
     if (!RegExp(r'^[\w-\.]+@...').hasMatch(value)) {
       return 'Invalid email';
     }
   }
   ```

4. **Use UI feedback consistently**
   ```dart
   // ✅ Correct
   AppHelper.showSuccess('Profile updated!');
   
   // ❌ Wrong (inconsistent UX)
   ScaffoldMessenger.of(context).showSnackBar(...);
   ```

---

## 🚫 Common Mistakes

### ❌ Mistake 1: Not using Obx()
```dart
// Won't update on theme change
Container(color: AppHelper.cardColor)
```

### ✅ Fix:
```dart
// Will update automatically
Obx(() => Container(color: AppHelper.cardColor))
```

### ❌ Mistake 2: Nested Obx with same observable
```dart
Obx(() {
  final isDark = AppHelper.isDarkMode;
  return Scaffold(
    body: Obx(() {  // ❌ Nested Obx observing same thing
      return Container(color: AppHelper.cardColor);
    }),
  );
})
```

### ✅ Fix:
```dart
Obx(() {
  return Scaffold(
    body: Container(color: AppHelper.cardColor),  // ✅ No nested Obx
  );
})
```

### ❌ Mistake 3: Using Get.isDarkMode directly
```dart
final isDark = Get.isDarkMode;  // ❌ Not using helper
```

### ✅ Fix:
```dart
final isDark = AppHelper.isDarkMode;  // ✅ Use helper
```

---

## 📚 More Examples

See `CORE_UTILITIES_REFACTORING.md` for:
- Complete architecture overview
- Migration guide
- Best practices
- Code quality metrics

---

**Quick Access:**
- Full Documentation: `CORE_UTILITIES_REFACTORING.md`
- Source Code: `lib/core/utils/helpers/app_helper.dart`
- Device Utils: `lib/core/utils/device/device_utility.dart`

---

**Last Updated:** February 11, 2026  
**Status:** ✅ Production Ready
