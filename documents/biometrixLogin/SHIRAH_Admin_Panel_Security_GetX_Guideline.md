# SHIRAH Admin Panel Security

## GetX Implementation Guideline

Flutter + Firebase + GetX Architecture

------------------------------------------------------------------------

# Objective

This document explains how to implement the SHIRAH Admin Panel security
system using:

-   GetX (State Management + Routing + Dependency Injection)
-   Firebase Authentication (Google Sign-In Only)
-   Firestore (Role-Based Access)
-   local_auth (Biometric)
-   flutter_secure_storage (Secure Local Storage)

Core Enforcement:

✔ Google Sign-In Only\
✔ Role Based Access\
✔ Mandatory Biometric\
✔ Fallback 6-Digit PIN\
✔ App Resume Verification\
✔ Secure Storage Only

------------------------------------------------------------------------

# 1. Dependency Injection (Initial Binding)

Use GetX Binding to inject services globally.

Example:
```dart
class InitialBinding extends Bindings { 
    @override void dependencies() {
        Get.put(AuthService(), permanent: true); 
        Get.put(BiometricService(), permanent: true); 
        Get.put(PinService(), permanent: true);
        Get.put(SecureStorageService(), permanent:true); 
    } 
}
```

Attach in `GetMaterialApp: initialBinding: InitialBinding()`

------------------------------------------------------------------------

# 2. Google Sign-In Flow (AuthService)

Responsibilities: 

- Google Sign-In 
- Firebase Authentication 
- Firestore role validation 
- Force logout if not admin


Flow:

1.  Google Sign-In
2.  Firebase credential login
3.  Fetch Firestore user document
4.  If role != "admin" → signOut()
5.  Navigate to Security Setup

Navigation Example: `Get.offAllNamed("/security-check");`

------------------------------------------------------------------------

# 3. Security Controller (Central Logic)

Create SecurityController extending GetxController.

Responsibilities:

-   Check biometric support
-   Enforce biometric setup
-   Enforce PIN setup
-   Handle app resume authentication
-   Manage lock state

Reactive State Example:
```dart
final isBiometricEnabled = false.obs; final isLocked = true.obs;
```

------------------------------------------------------------------------

# 4. Biometric Implementation (BiometricService)

Logic:

1.  Check device support
2.  If supported → authenticate with biometricOnly = true
3.  On success → store flag in secure storage
4.  On failure → block access

Mandatory rule: Dashboard cannot open unless biometric_enabled == true
OR PIN created successfully.

------------------------------------------------------------------------

# 5. Fallback 6-Digit PIN (PinService)

Rules:

-   Exactly 6 digits
-   SHA256 hash before saving
-   Store hash in flutter_secure_storage
-   Never store raw PIN

Flow:

Create PIN → Confirm PIN → Hash → Save → Mark security setup complete

Verification:

Input PIN → Hash → Compare with stored hash → Unlock

------------------------------------------------------------------------

# 6. App Resume Verification

Use `WidgetsBindingObserver` inside `SecurityController`.

Override:

`didChangeAppLifecycleState(AppLifecycleState state)`

If state == resumed:

    IF biometric_enabled == true:
        Trigger biometric authentication
    ELSE:
        Show PIN verification screen

Access to dashboard remains blocked until verification passes.

------------------------------------------------------------------------

# 7. Route Protection (Middleware)

Use GetMiddleware to protect admin routes.

Example:

```dart
class AdminMiddleware extends GetMiddleware {
    @override RouteSettings? redirect(String? route) {
        final securityController = Get.find<SecurityController>();

        if (securityController.isLocked.value == true) {
            return RouteSettings(name: "/lock");
        }

        return null;
    } 
}
```

Attach middleware to admin route.

------------------------------------------------------------------------

# 8. Secure Storage Rules

Use `flutter_secure_storage` for:

-   `biometric_enabled` flag
-   `hashed_pin`
-   `security_setup_completed`

Never store: - raw PIN - tokens manually - admin role locally

Always validate role from Firestore after login.

------------------------------------------------------------------------

# 9. Complete Flow (GetX Version)

            App Start 
                ↓ 
           Login Screen 
                ↓ 
          Google Sign-In 
                ↓ 
        Firestore Role Check 
                ↓
        Security Setup Check 
                ↓ 
        Biometric Supported? 
        ↓                  ↓ 
       Yes                 No 
        ↓                  ↓ 
    Enable Bio      Create 4-digit PIN 
        ↓                   ↓ 
        Unlock Admin Dashboard 
                ↓ 
          App Background? 
                ↓ 
              Resume
                → Force Re-Authentication

------------------------------------------------------------------------

# 10. Security Principles

-   Zero Plain Text Storage
-   Mandatory Local Verification
-   Role-Based Authorization
-   Route-Level Protection
-   Resume-Time Authentication
-   Secure Dependency Injection

------------------------------------------------------------------------

# Production Recommendation

For maximum stability:

-   Keep SecurityController permanent using Get.put(permanent: true)
-   Prevent multiple controller instances
-   Use Get.offAll() after login to clear navigation stack
-   Disable back navigation from lock screen
-   Enforce re-authentication before every sensitive action

------------------------------------------------------------------------

# Conclusion

Using GetX allows clean separation of:

-   Authentication Layer
-   Security Layer
-   Admin Business Logic

This creates a structured, scalable, and production-ready security model
for SHIRAH Admin Panel.
