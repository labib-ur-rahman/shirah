# Home Feed System – Flutter Implementation Guide

> **Version:** 1.0  
> **Last Updated:** February 14, 2026  
> **Synced With:** `unified_home_feed_system_full_reference_documentation_version_3.md`  
> **Stack:** Flutter + GetX + Firebase (Firestore + Cloud Functions)

---

## 📋 Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Firestore Collection: `/home_feeds`](#2-firestore-collection-home_feeds)
3. [Cloud Functions (Triggers + Callable)](#3-cloud-functions)
4. [Flutter Data Layer (Model + Repository)](#4-flutter-data-layer)
5. [Flutter Controller Layer](#5-flutter-controller-layer)
6. [Flutter UI Layer](#6-flutter-ui-layer)
7. [Feed Item Types Reference](#7-feed-item-types-reference)
8. [Ad Gap Algorithm](#8-ad-gap-algorithm)
9. [Localization](#9-localization)
10. [File Map](#10-file-map)

---

## 1. Architecture Overview

```
┌─────────────────────────────────────────┐
│                HOME SCREEN              │
│  (UI: HomeScreen + FeedItemBuilder)     │
├─────────────────────────────────────────┤
│          HomeFeedController             │
│  (State: feedItems, resolvedPosts...)   │
├─────────────────────────────────────────┤
│          HomeFeedRepository             │
│  (Firebase: /home_feeds, /posts, /jobs) │
├─────────────────────────────────────────┤
│          Firestore + Cloud Functions    │
│  (Auto feed creation on post/job        │
│   approval, admin native ad mgmt)       │
└─────────────────────────────────────────┘
```

### Golden Rules
1. `home_feeds` decides **WHAT** to show and **WHEN** — never **WHAT** the content is
2. Content lives in `/posts`, `/jobs` — feed only references via `refId`
3. Ad gap algorithm runs in Flutter, NOT in Firestore
4. Feed items are auto-created by Cloud Functions triggers on approval
5. Native Ad feeds are admin-only (callable function with RBAC)

---

## 2. Firestore Collection: `/home_feeds`

### Document Structure

```json
{
  "feedId": "feed_abc123",
  "type": "COMMUNITY_POST",
  "refId": "post_abc123",
  "priority": 10,
  "status": "ACTIVE",
  "visibility": "PUBLIC",
  "createdAt": "Timestamp",
  "meta": {
    "authorId": "uid_1",
    "adminPinned": false,
    "boosted": false
  }
}
```

### Feed Ordering Query

```sql
WHERE status == "ACTIVE"
ORDER BY priority DESC
ORDER BY createdAt DESC
LIMIT 20
```

> **Requires Firestore Composite Index:**  
> Collection: `home_feeds`  
> Fields: `status ASC`, `priority DESC`, `createdAt DESC`

### ENUMs

| ENUM | Values |
|------|--------|
| FeedItemType | `COMMUNITY_POST`, `MICRO_JOB`, `NATIVE_AD`, `RESELLING`, `DRIVE_OFFER`, `SUGGESTED_FOLLOWING`, `ON_DEMAND_POST`, `BUY_SELL_POST`, `SPONSORED`, `ADS_VIEW`, `ANNOUNCEMENT` |
| FeedStatus | `ACTIVE`, `DISABLED`, `HIDDEN`, `REMOVED` |
| FeedVisibility | `PUBLIC`, `FRIENDS`, `ONLY_ME` |
| FeedPriority | `5 (LOW)`, `10 (NORMAL)`, `20 (IMPORTANT)`, `30 (CRITICAL)` |

### Priority Mapping

| Priority | Used By |
|----------|---------|
| 5 (LOW) | Suggested Following |
| 10 (NORMAL) | Community Post, On Demand Post, Buy/Sell Post, Announcement |
| 20 (IMPORTANT) | Micro Job, Reselling, Drive Offer |
| 30 (CRITICAL) | Native Ad, Sponsored, Ads View |

---

## 3. Cloud Functions

### File: `functions/src/features/home-feed/home-feed-operations.ts`

### Firestore Triggers (Automatic)

| Trigger | Event | Action |
|---------|-------|--------|
| `onPostApproved` | Post status → approved | Creates COMMUNITY_POST feed item |
| `onJobApproved` | Job status → APPROVED | Creates MICRO_JOB feed item |
| `onPostDeleted` | Post deleted/rejected | Sets feed status → REMOVED |
| `onJobStatusChange` | Job completed/paused | Sets feed status accordingly |

### Callable Functions (Admin)

| Function | Access | Purpose |
|----------|--------|---------|
| `createNativeAdFeed` | Admin only | Create NATIVE_AD feed placeholder |
| `updateFeedItemStatus` | Admin/Moderator | Enable/disable/remove feeds |
| `updateFeedItemPriority` | Admin only | Change feed ordering priority |
| `getAdminFeedItems` | Admin/Moderator | List feeds with filters |

### Security
- All callable functions verify RBAC roles
- Every status/priority change is audit-logged
- Native Ad creation requires Admin+ role

---

## 4. Flutter Data Layer

### Model: `lib/data/models/feed/feed_item_model.dart`

Key classes:
- `FeedItemType` — Static string constants for all feed types
- `FeedVisibility` — PUBLIC, FRIENDS, ONLY_ME
- `FeedStatus` — ACTIVE, DISABLED, HIDDEN, REMOVED
- `FeedPriority` — Numeric priority values with `forType()` helper
- `FeedMetaModel` — Extension-safe metadata container
- `FeedRulesModel` — Ad gap/frequency rules
- `FeedItemModel` — Main feed document model with `fromFirestore()` / `toCreateMap()`

### Repository: `lib/data/repositories/home_feed_repository.dart`

| Method | Purpose |
|--------|---------|
| `fetchFeedItems()` | Paginated feed query with cursor |
| `resolvePost()` | Fetch single post by refId |
| `resolveJob()` | Fetch single job by refId |
| `batchResolvePosts()` | Batch fetch posts (max 30 per query) |
| `batchResolveJobs()` | Batch fetch jobs (max 30 per query) |
| `watchFeedItems()` | Real-time stream listener |
| `createFeedItem()` | Admin/test feed creation |
| `updateFeedStatus()` | Status update |

---

## 5. Flutter Controller Layer

### Controller: `lib/features/home/controllers/home_feed_controller.dart`

| State | Type | Purpose |
|-------|------|---------|
| `feedItems` | `RxList<FeedItemModel>` | Processed feed items (after ad gap) |
| `resolvedPosts` | `RxMap<String, CommunityPostModel>` | Cached resolved posts |
| `resolvedJobs` | `RxMap<String, MicroJobModel>` | Cached resolved jobs |
| `isLoading` | `RxBool` | Initial load state |
| `isLoadingMore` | `RxBool` | Pagination load state |
| `hasMore` | `RxBool` | Whether more pages exist |
| `hasError` | `RxBool` | Error state |

| Method | Purpose |
|--------|---------|
| `loadFeed()` | Initial feed load |
| `loadMore()` | Pagination (infinite scroll) |
| `refreshFeed()` | Pull-to-refresh |
| `getPost(refId)` | Get cached post |
| `getJob(refId)` | Get cached job |
| `isContentResolved(item)` | Check if content loaded |

### Progressive Loading Flow

```
1. Fetch feed items from /home_feeds (fast, small docs)
2. Render feed list immediately (shimmer for unresolved)
3. Batch resolve posts & jobs in parallel (non-blocking)
4. UI updates reactively as content loads (Obx)
5. Never block screen for child data
```

---

## 6. Flutter UI Layer

### Home Screen: `lib/features/home/views/screens/home_screen.dart`

Structure:
```
ListView.builder
  ├── [0] CreatePostSection (static)
  ├── [1] QuickActionsSection (static)
  ├── [2..n] FeedItemBuilder (dynamic per feed item)
  └── [n+1] Loading indicator / End of feed
```

### Feed Item Builder: `lib/features/home/views/widgets/feed/feed_item_builder.dart`

Single `switch` statement per documentation v3 section 15:

```dart
switch (feedItem.type) {
  case FeedItemType.communityPost → CommunityPostCard
  case FeedItemType.microJob → MicroJobCard
  case FeedItemType.nativeAd → NativeAdPlaceholder
  // Future types → SizedBox.shrink()
}
```

### Widget Files

| Widget | Path | Purpose |
|--------|------|---------|
| FeedItemBuilder | `widgets/feed/feed_item_builder.dart` | Type dispatcher |
| FeedShimmerCard | `widgets/feed/feed_shimmer_card.dart` | Loading placeholder |
| FeedEmptyState | `widgets/feed/feed_empty_state.dart` | Empty feed UI |
| FeedErrorState | `widgets/feed/feed_error_state.dart` | Error with retry |
| NativeAdPlaceholder | `widgets/feed/native_ad_placeholder.dart` | Ad slot with badge |
| HomeFeedList | `widgets/feed/home_feed_list.dart` | Standalone feed list |

---

## 7. Feed Item Types Reference

### Running (Implemented)

| Type | Priority | Visibility | Card Widget |
|------|----------|-----------|-------------|
| `COMMUNITY_POST` | 10 | PUBLIC/FRIENDS/ONLY_ME | CommunityPostCard |
| `MICRO_JOB` | 20 | PUBLIC | MicroJobCard |

### Upcoming (Enum defined, UI placeholder)

| Type | Priority | Description |
|------|----------|-------------|
| `RESELLING` | 20 | Product reselling card |
| `DRIVE_OFFER` | 20 | Horizontal offers list |
| `SUGGESTED_FOLLOWING` | 5 | Horizontal friends list |
| `ON_DEMAND_POST` | 10 | User product request |
| `BUY_SELL_POST` | 10 | Used product listing |
| `SPONSORED` | 30 | Official sponsored post |
| `ANNOUNCEMENT` | 10 | Admin announcement |
| `ADS_VIEW` | 30 | Daily ad progress |
| `NATIVE_AD` | 30 | AdMob native ad |

---

## 8. Ad Gap Algorithm

Implemented in `HomeFeedController._applyAdGapAlgorithm()`

```
shownAds = 0
itemsSinceLastAd = ∞ (999)

for each item in rawFeedItems:
  if item is NATIVE_AD:
    if emergency paused → SKIP
    if shownAds >= maxPerSession → SKIP
    if itemsSinceLastAd < minGap → SKIP
    SHOW AD → shownAds++, itemsSinceLastAd = 0
  else:
    SHOW ITEM → itemsSinceLastAd++
```

Default rules: `minGap = 6`, `maxPerSession = 3`  
Rules can be overridden per ad feed item via the `rules` field.

---

## 9. Localization

All feed-related strings use `AppStrings.feedXxx` pattern.

| Key | EN | BN |
|-----|----|----|
| `feed_empty` | No feed items yet | এখনো কোনো ফিড নেই |
| `feed_ad_badge` | Ad | বিজ্ঞাপন |
| `feed_sponsored_badge` | Sponsored | স্পন্সরড |
| `feed_announcement_badge` | Announcement | ঘোষণা |
| `feed_micro_job_badge` | Micro Job | মাইক্রো জব |
| `feed_end_of_feed` | You're all caught up! | আপনি সব দেখেছেন! |

---

## 10. File Map

```
functions/src/
└── features/home-feed/
    └── home-feed-operations.ts    # Cloud Functions (triggers + callable)

lib/
├── core/
│   ├── bindings/
│   │   └── initial_binding.dart   # HomeFeedRepository + HomeFeedController registered
│   ├── localization/
│   │   ├── app_string_localizations.dart  # AppStrings.feedXxx
│   │   └── languages/
│   │       ├── en_us.dart         # English feed strings
│   │       └── bn_bd.dart         # Bangla feed strings
│   └── utils/constants/
│       └── firebase_paths.dart    # homeFeeds collection path
│
├── data/
│   ├── models/feed/
│   │   └── feed_item_model.dart   # FeedItemModel, FeedItemType, FeedStatus, etc.
│   └── repositories/
│       └── home_feed_repository.dart  # Firestore operations
│
└── features/home/
    ├── controllers/
    │   └── home_feed_controller.dart  # Feed state + ad gap algorithm
    └── views/
        ├── screens/
        │   └── home_screen.dart       # Updated to use unified feed
        └── widgets/feed/
            ├── feed_item_builder.dart    # Type dispatcher
            ├── feed_shimmer_card.dart    # Loading skeleton
            ├── feed_empty_state.dart     # Empty state
            ├── feed_error_state.dart     # Error with retry
            ├── native_ad_placeholder.dart # Ad slot placeholder
            └── home_feed_list.dart       # Standalone feed list widget
```

---

## Required Firestore Index

Create this composite index in Firebase Console:

```
Collection: home_feeds
Fields:
  - status: Ascending
  - priority: Descending
  - createdAt: Descending
```

---

**END OF DOCUMENT – Home Feed Flutter Implementation Guide v1.0**
