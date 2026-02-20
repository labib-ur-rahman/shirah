# Google Play Developer Policy 2026 — SHIRAH Compliance Audit

> **Audit Date:** February 21, 2026  
> **Policy Baseline:** Google Play Developer Program Policies (including November 2025 updates)  
> **App:** SHIRAH — Business & Community Super App for Bangladesh  
> **Package:** com.shirahsoft.app

---

## Executive Summary

| # | Policy Area | Status | Priority |
|---|-------------|--------|----------|
| 1 | Payments (Google Play Billing) | ⚠️ **RISK** | 🔴 Critical |
| 2 | Financial Services | ⚠️ **RISK** | 🟡 High |
| 3 | MLM / Pyramid Detection | ⚠️ **RISK** | 🔴 Critical |
| 4 | User Data & Privacy | ⚠️ **RISK** | 🔴 Critical |
| 5 | WebView Payment | ✅ Compliant | 🟢 Low |
| 6 | Misleading Claims | ⚠️ **RISK** | 🟡 High |
| 7 | Permissions | ✅ Compliant | 🟢 Low |
| 8 | Content Rating | ✅ Compliant | 🟢 Low |

---

## 1. PAYMENTS POLICY — Alternative Billing & Service Fees

### Status: ⚠️ RISK (Medium-High)

**What the app does:**
- Charges 250 BDT (~$2.10 USD) for "Profile Verification" via UddoktaPay WebView
- Charges 400 BDT (~$3.40 USD) for "Lifetime Subscription" via UddoktaPay WebView
- Payment methods: bKash, Nagad, Rocket (local Bangladeshi MFS)
- No Google Play Billing integration

**Policy reference:** [Google Play Billing Policy](https://support.google.com/googleplay/android-developer/answer/9858738)

**Analysis:** These payments unlock digital features within the app (verification badge, premium access, reward point earning capability). Google's policy states that all in-app purchases of digital goods/services must use Google Play Billing. Bangladesh is NOT in the User Choice Billing program.

**Key distinction that may help:** Verification involves genuine KYC (identity verification with admin review), and subscription unlocks real-world business tools (reselling, micro-jobs marketplace).

### Recommendations:
1. **Reframe "Verification" as genuine KYC** — emphasize document submission and manual admin review
2. **Reframe "Subscription" as "Business Account Upgrade"** for marketplace/reselling access
3. Add prominent disclosure that payments are for real-world business services
4. Prepare policy appeal document explaining UddoktaPay is necessary for Bangladeshi MFS (bKash/Nagad)

---

## 2. FINANCIAL SERVICES POLICY

### Status: ⚠️ RISK (Medium)

**What the app does:**
- Wallet Balance (BDT) — real fiat money, withdrawable to bKash/Nagad/Rocket
- Reward Points — non-cash, convertible at 100:1 BDT
- Mobile top-up/recharge services
- Manual withdrawal processing

**Policy reference:** [Financial Services Policy](https://support.google.com/googleplay/android-developer/answer/9876821)

### Recommendations:
1. Add Financial Services Disclosure in Play Store listing
2. Clarify SHIRAH does NOT hold funds — earnings come from completed activities
3. Add fee transparency for withdrawal fees
4. Consult Bangladesh fintech lawyer about e-money license requirements

---

## 3. MULTI-LEVEL MARKETING / PYRAMID DETECTION

### Status: ⚠️ RISK (High)

**What the app does:**
- Verification: 12,500 RP distributed across **10 levels** of uplines
- Subscription: 24,000 RP distributed across **15 levels** of uplines
- Invite code system drives recruitment
- Network stats tracked per level

**What users see:** "My Community" / "People You Invited" — no level numbers, no income trees

**Policy reference:** [Deceptive Behavior Policy](https://support.google.com/googleplay/android-developer/answer/9888076)

**Analysis:** Even though the UI hides the MLM structure, Google's automated and manual review can examine database structure and Cloud Functions code. 10-15 levels of commission distribution is a textbook MLM pattern.

### Recommendations:
1. **CRITICAL:** Reduce commission levels to 3-5 maximum
2. Rename backend terminology: `upline` → `referrer`, `commission` → `referralReward`, `level` → `tier`
3. Ensure >50% of reward distribution comes from non-recruitment activities
4. Never show "earn by inviting" messaging — use "community building rewards"
5. Add "Income Disclaimer" screen in settings

---

## 4. USER DATA & PRIVACY

### Status: ⚠️ RISK (Medium)

**Data collected:** Full name, email, phone, profile photo, biometric data (on-device via local_auth), push notification tokens, payment info, financial data

**Missing requirements:**
- ❌ Privacy Policy URL not found/hosted
- ❌ Account deletion feature not implemented
- ❌ No explicit consent flow for data collection

### Recommendations:
1. **MANDATORY:** Create and host a Privacy Policy at a public URL
2. **MANDATORY:** Implement account deletion feature (`deleteMyAccount` Cloud Function)
3. **MANDATORY:** Complete Data Safety Section in Play Console
4. Add consent dialog on first launch
5. Disclose biometric usage in Data Safety

---

## 5. WEBVIEW PAYMENT COMPLIANCE

### Status: ✅ COMPLIANT

The WebView is used to display a third-party payment gateway (UddoktaPay). This is a standard integration pattern. Payment verification happens server-side.

### Recommendations:
1. Add URL allowlisting in WebView `onNavigationRequest` to prevent open redirects
2. Consider SSL certificate pinning for payment domain

---

## 6. MISLEADING CLAIMS / DECEPTIVE BEHAVIOR

### Status: ⚠️ RISK (Medium)

**Concerns:**
- "Earn money" messaging could trigger scrutiny
- "Watch ads → earn RP → convert to BDT → withdraw" pipeline could be flagged
- Reward streak multiplier system needs clear disclosure

### Recommendations:
1. Replace "Earn Money" with "Earn Rewards" everywhere
2. Add disclaimers: "Reward Points are not money until converted"
3. Lead Play Store description with business services, not earnings
4. Do not show potential earnings calculations before signup

---

## 7. PERMISSIONS

### Status: ✅ COMPLIANT

Minimal permission set: Camera (profile photo), Storage (media access with proper scoping), Internet.

### Recommendations:
1. Verify `POST_NOTIFICATIONS` declared for Android 13+
2. Add runtime permission rationale dialogs

---

## 8. CONTENT RATING

### Status: ✅ COMPLIANT

Expected IARC rating: 12+ / Teen (financial transactions + user-generated content + social features).

### Recommendations:
1. Complete IARC questionnaire accurately
2. Implement content moderation for community posts
3. Do NOT target app for children under 13

---

## TOP 5 ACTION ITEMS (Before Play Store Submission)

| # | Action | Impact | Effort |
|---|--------|--------|--------|
| 1 | Privacy Policy + Account Deletion | 🔴 Hard rejection without these | Medium |
| 2 | Reframe payments as real-world services | 🔴 Potential takedown | Low (messaging changes) |
| 3 | Reduce commission levels to 3-5 | 🔴 Potential takedown for MLM | High (backend changes) |
| 4 | Rewrite "earn money" messaging | 🟡 Could trigger review | Low |
| 5 | Complete Data Safety Section | 🔴 Required for submission | Low |

---

*This audit should be reviewed before every major release and when Google updates their policies.*
