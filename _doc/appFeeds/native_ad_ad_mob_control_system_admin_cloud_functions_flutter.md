# Native Ad (AdMob) Control System – Full Reference Documentation

> **Purpose**\
> This document explains **end‑to‑end implementation** of **AdMob Native Ads** inside the unified Home Feed using:
>
> - Firebase Firestore
> - Firebase Cloud Functions
> - Flutter (User App)
> - Admin Panel
>
> It is written as a **long‑term reference** so that:
>
> - You can read it **1 year later** and still understand the full flow
> - Any **new developer** can implement or maintain it
> - **Admins** clearly know what they control
> - **Cloud Functions responsibilities** are unambiguous

---

## 1️⃣ Feed Item Type ENUM (Global – MUST NOT CHANGE)

```ts
FeedItemType = {
  COMMUNITY_POST,
  MICRO_JOB,
  NATIVE_AD,

  // future‑ready
  RESELLING,
  DRIVE_OFFER,
  SUGGESTED_FOLLOWING,
  ON_DEMAND_POST,
  BUY_SELL_POST,
  SPONSORED,
  ADS_VIEW,
  ANNOUNCEMENT
}
```

Why ENUM:

- Prevents invalid feed items
- Keeps Flutter rendering clean
- Enables safe feature rollout

---

## 2️⃣ Core Principle (Must Understand First)

> **AdMob Native Ads are NOT content.**\
> They are **SDK‑controlled ads**.

Therefore:

- ❌ Firestore never stores ad text, image, CTA
- ❌ Cloud Functions never load ads
- ✅ Flutter app loads ads via AdMob SDK

Firestore only stores **WHERE an ad may appear**.

---

## 3️⃣ Firestore Collection Used

```
home_feeds (Collection)
└── {feedId} (Document)
```

This is the **only collection queried** by the Home Feed UI.

---

## 4️⃣ Native Ad Feed Document Structure

```json
{
  "feedId": "feed_ad_001",

  "type": "NATIVE_AD",
  "refId": "admob_native_home",

  "priority": 15,

  "status": "ACTIVE",
  "visibility": "PUBLIC",

  "createdAt": "timestamp",

  "meta": {
    "adProvider": "ADMOB",
    "placement": "HOME_FEED",
    "minGap": 6,
    "maxPerSession": 3
  }
}
```

### Why each field exists

| Field              | Reason                             |
| ------------------ | ---------------------------------- |
| type               | Tells Flutter to render Native Ad  |
| refId              | Logical placement ID (not real ad) |
| priority           | Feed ordering control              |
| status             | Admin enable / disable             |
| meta.minGap        | Policy‑safe spacing                |
| meta.maxPerSession | Prevents ad spam                   |

---

## 5️⃣ What Admin Does (Manual Control)

### Admin Responsibilities

Admins **DO NOT manage ads themselves**. They manage **ad placeholders**.

### Admin Can:

- Create `NATIVE_AD` feed documents
- Enable / disable ads (`status`)
- Emergency pause (bulk update)
- Adjust priority & spacing

### Admin Panel UI Example

| Setting          | Action                         |
| ---------------- | ------------------------------ |
| Enable Ads       | status = ACTIVE                |
| Disable Ads      | status = HIDDEN                |
| Emergency Stop   | Update all NATIVE\_AD → HIDDEN |
| Change Frequency | Update meta.minGap             |

---

## 6️⃣ Cloud Functions – What They SHOULD Do

### ✅ Responsibilities

1. **Create Feed Placeholder** (optional automation)
2. **Remove feed items on cleanup**
3. **Audit logging**
4. **Protect write access**

### ❌ Must NEVER Do

- Load ads
- Decide ad content
- Force impressions

---

## 7️⃣ Cloud Function Example (Create Native Ad Placeholder)

```ts
exports.createNativeAdFeed = onCall(async (_, context) => {
  if (!isAdmin(context.auth.uid)) throw new Error('Forbidden');

  await firestore.collection('home_feeds').add({
    type: 'NATIVE_AD',
    refId: 'admob_native_home',
    priority: 15,
    status: 'ACTIVE',
    visibility: 'PUBLIC',
    createdAt: serverTimestamp(),
    meta: {
      adProvider: 'ADMOB',
      placement: 'HOME_FEED',
      minGap: 6,
      maxPerSession: 3
    }
  });
});
```

This creates **only a placeholder**, not an ad.

---

## 8️⃣ Flutter App – Where Real Ad Logic Lives

> **ALL AdMob logic lives in Flutter.**

### Flutter Responsibilities

- Load AdMob SDK
- Request Native Ads
- Render ad UI
- Track impressions & clicks

---

## 9️⃣ Flutter Native Ad Widget (Conceptual Example)

```dart
class FeedNativeAd extends StatefulWidget {
  @override
  State<FeedNativeAd> createState() => _FeedNativeAdState();
}

class _FeedNativeAdState extends State<FeedNativeAd> {
  NativeAd? _ad;
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    _ad = NativeAd(
      adUnitId: AdUnitIds.homeFeedNative,
      factoryId: 'feed',
      listener: NativeAdListener(
        onAdLoaded: (_) => setState(() => loaded = true),
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
      request: const AdRequest(),
    )..load();
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) return const SizedBox();
    return AdWidget(ad: _ad!);
  }
}
```

---

## 🔟 Flutter Feed Rendering Logic

```dart
switch (feedItem.type) {
  case FeedItemType.COMMUNITY_POST:
    return CommunityPostCard(feedItem.refId);

  case FeedItemType.MICRO_JOB:
    return MicroJobCard(feedItem.refId);

  case FeedItemType.NATIVE_AD:
    return FeedNativeAd();
}
```

---

## 1️⃣1️⃣ Ad Display Rules (Policy Safe)

| Rule          | Value                 |
| ------------- | --------------------- |
| First Ad      | After 5–7 items       |
| Min Gap       | ≥ meta.minGap         |
| Max / Session | meta.maxPerSession    |
| Label         | "Sponsored" mandatory |

If ad fails → show nothing.

---

## 1️⃣2️⃣ Automated vs Manual Summary

### Manual (Admin)

- Create / remove placeholders
- Enable / disable ads
- Emergency stop

### Automated (Flutter + SDK)

- Ad selection
- Bidding
- Revenue tracking
- Impression counting

---

## 1️⃣3️⃣ Audit Logging (Recommended)

Log:

- ad.placeholder.create
- ad.placeholder.disable
- ad.placeholder.enable

Stored in `/audit_logs`.

---

## 1️⃣4️⃣ Why This Is Production‑Safe

✔ Fully Play Store compliant\
✔ No misleading ads\
✔ Clean responsibility separation\
✔ Easy rollback\
✔ Scales with new feed types

---

## Final Rule (Memorize This)

> **Firestore decides WHERE ads may appear.**\
> **Flutter + AdMob decides WHICH ad appears.**

Never mix these roles.

---

**END OF DOCUMENT**

