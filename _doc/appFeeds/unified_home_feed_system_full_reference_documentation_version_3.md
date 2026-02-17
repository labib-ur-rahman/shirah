# Unified Home Feed System – Full Reference Documentation (v3)

> **IMPORTANT NOTICE**  
> This is the **FINAL, COMPLETE, NO-MISSING-PIECE** reference document for the Unified Home Feed system.  
> Every field, enum, responsibility, algorithm step, and control flow is explicitly documented.
>
> If this document is followed exactly, the system will be:
> - Scalable
> - Cost-efficient
> - Google Play policy–safe
> - Maintainable for 5+ years

---

## 1️⃣ Core Philosophy (Read This First)

### What the Home Feed IS
- A **presentation + control layer**
- A **single ordered stream** of heterogeneous items
- A **moderation-friendly abstraction**

### What the Home Feed is NOT
- ❌ A place to store post/job/ad content
- ❌ A business logic engine
- ❌ A replacement for `/posts` or `/micro_jobs`

> 🔑 **Golden Rule**  
> `home_feeds` decides **WHAT to show and WHEN**, never **WHAT the content is**.

---

## 2️⃣ Feed Item Type ENUM (System Contract)

```ts
enum FeedItemType {
  COMMUNITY_POST,
  MICRO_JOB,
  NATIVE_AD,

  // future-ready (DO NOT implement yet)
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

### Why ENUM is mandatory
- Prevents invalid feed rendering
- Enables single `switch` in Flutter
- Required for Firestore rules validation
- Prevents accidental feature leakage

---

## 3️⃣ Feed Visibility ENUM

```ts
enum FeedVisibility {
  PUBLIC,     // visible to everyone
  FRIENDS,    // visible only to followers
  ONLY_ME     // visible only to author
}
```

### Visibility Rules by Type
| Type | Allowed Visibility |
|----|-------------------|
| COMMUNITY_POST | PUBLIC, FRIENDS, ONLY_ME |
| MICRO_JOB | PUBLIC only |
| NATIVE_AD | PUBLIC only |

---

## 4️⃣ Feed Status ENUM

```ts
enum FeedStatus {
  ACTIVE,     // eligible for feed
  DISABLED,   // paused (ads, admin control)
  HIDDEN,     // admin hidden
  REMOVED     // policy violation
}
```

---

## 5️⃣ Feed Priority ENUM (Semantic Meaning)

```ts
enum FeedPriority {
  LOW = 5,
  NORMAL = 10,
  IMPORTANT = 20,
  CRITICAL = 30
}
```

### Mapping
| Priority | Used By |
|-------|--------|
| 10 | Community Post |
| 20 | Micro Job |
| 30 | Native Ad / Sponsored |

> Priority controls **frequency bias**, NOT absolute position.

---

## 6️⃣ `/home_feeds` Collection (Authoritative Feed Index)

```
home_feeds (Collection)
└── {feedId} (Document)
```

### Why a Dedicated Feed Collection
| Reason | Explanation |
|-----|------------|
| Cost | One paginated query |
| Control | Central moderation |
| Flexibility | Unlimited feed types |
| Safety | Ads isolated from content |

---

## 7️⃣ Base Feed Document – FULL STRUCTURE

```json
{
  "feedId": "feed_001",              // document ID (duplicated for debug)

  "type": "COMMUNITY_POST",         // FeedItemType ENUM
  "refId": "post_abc123",           // Reference ID (nullable for ads)

  "priority": 10,                     // FeedPriority value
  "status": "ACTIVE",               // FeedStatus ENUM
  "visibility": "PUBLIC",           // FeedVisibility ENUM

  "createdAt": "timestamp",         // feed insertion time

  "meta": {
    "authorId": "uid_1",             // content owner (null for ads)
    "adminPinned": false,              // future use
    "boosted": false                   // future monetization
  }
}
```

### Field-by-Field Explanation
| Field | Why it exists |
|----|--------------|
| feedId | Debugging & audit clarity |
| type | Rendering decision (Determines which UI card to render) |
| refId | Links to real content  (`posts` / `jobs`) |
| priority | Ordering bias - Controls feed mixing (jobs > posts) |
| status | Kill-switch control (Admin moderation without deleting data) |
| visibility | Privacy enforcement (Privacy filtering at feed level)|
| createdAt | Time decay |
| meta | Extension-safe container (Algorithm & admin control flags) |

---

## 8️⃣ Feed Ordering Algorithm (EXACT)

### Firestore Query
```sql
WHERE status == ACTIVE
ORDER BY priority DESC
ORDER BY createdAt DESC
LIMIT 20
```

### Why This Works
- Ads/jobs rise without dominating
- New content replaces old naturally
- No per-user expensive queries

---

## 9️⃣ COMMUNITY_POST Feed Document

```json
{
  "type": "COMMUNITY_POST",
  "refId": "post_abc123",
  "priority": 10,
  "status": "ACTIVE",
  "visibility": "FRIENDS",
  "createdAt": "timestamp",
  "meta": {
    "authorId": "uid_author"
  }
}
```

### Notes
- Real post data lives in `/posts`
- Feed only references it
- Visibility enforced in Flutter

---

## 🔟 MICRO_JOB Feed Document

```json
{
  "type": "MICRO_JOB",
  "refId": "job_789",
  "priority": 20,
  "status": "ACTIVE",
  "visibility": "PUBLIC",
  "createdAt": "timestamp",
  "meta": {
    "authorId": "uid_job_owner"
  }
}
```

### Why Higher Priority
- Revenue-related
- Time-sensitive
- Limited inventory

---

## 1️⃣1️⃣ NATIVE_AD Feed Document (FULL)

```json
{
  "type": "NATIVE_AD",
  "refId": null,

  "priority": 30,
  "status": "ACTIVE",
  "visibility": "PUBLIC",

  "createdAt": "timestamp",

  "rules": {
    "minGap": 6,               // minimum items between ads
    "maxPerSession": 3         // max ads per app session
  },

  "meta": {
    "adUnitId": "ca-app-pub-xxx/native",
    "platform": "android",   // android | ios
    "emergencyPause": false
  }
}
```

### Why `rules` exists
- Keeps feed rules separate from content
- Future-proof for new constraints

---

## 1️⃣2️⃣ Ad Gap Algorithm (Flutter – Mandatory)

```text
shownAds = 0
itemsSinceLastAd = ∞

for item in feed:
  if item.type == NATIVE_AD:
    if shownAds >= maxPerSession → SKIP
    if itemsSinceLastAd < minGap → SKIP
    SHOW AD
    shownAds++
    itemsSinceLastAd = 0
  else:
    SHOW ITEM
    itemsSinceLastAd++
```

> Firestore NEVER decides gaps.

---

## 1️⃣3️⃣ Cloud Functions Responsibilities

### MUST DO
- Admin-only write protection for NATIVE_AD
- Audit log every status change
- Global ads enable/disable flag

### MUST NOT DO
- Fetch ads
- Track impressions
- Inject ads into feed

---

## 1️⃣4️⃣ Admin Panel Controls

### Admin Can
- Create NATIVE_AD feed docs
- Change priority
- Pause ads (`status = DISABLED`)
- Emergency kill switch

### Admin Cannot
- See ad content
- Manipulate impressions

---

## 1️⃣5️⃣ Flutter Rendering (Final Pattern)

```dart
Widget buildFeedItem(FeedItem feed) {
  switch (feed.type) {
    case FeedItemType.COMMUNITY_POST:
      return CommunityPostCard(feed.refId);

    case FeedItemType.MICRO_JOB:
      return MicroJobCard(feed.refId);

    case FeedItemType.NATIVE_AD:
      return NativeAdWidget(feed.meta.adUnitId);
  }
}
```

---

## 1️⃣6️⃣ Why Ads Are Placeholders Only

| Reason | Explanation |
|----|-------------|
| Policy | Ad content must come from SDK |
| Security | Prevents fraud |
| Revenue | SDK bidding optimization |

---

## 1️⃣7️⃣ Automated vs Manual Summary

### Manual (Admin)
- Feed doc creation
- Enable/disable
- Priority tuning

### Automated (Flutter)
- SDK load
- Gap enforcement
- Impression tracking

### Automated (Cloud Functions)
- Security
- Audit logs
- Global config

---

## 1️⃣8️⃣ Play Store Safety Checklist

- ✔ Ads clearly labeled
- ✔ No forced clicks
- ✔ No misleading UI
- ✔ Ads never replace content

---

## 1️⃣9️⃣ Final Guarantees

If you follow this document:
- No hidden logic
- No undefined behavior
- No refactor needed for future feed types

---

**END OF DOCUMENT – Unified Home Feed System (v3, COMPLETE)**

