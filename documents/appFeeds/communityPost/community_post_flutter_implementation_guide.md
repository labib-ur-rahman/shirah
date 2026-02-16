# Community Post System - Flutter Implementation Guide

> Complete implementation guide for shirah's Community Post feature.

---

## 📁 File Structure

```
lib/
├── data/
│   ├── models/community/
│   │   ├── community_post_model.dart     # Core post model (PostPrivacy, PostStatus)
│   │   ├── post_author_model.dart        # Embedded author (uid, name, photo)
│   │   ├── reaction_summary_model.dart   # Aggregated reaction counts + ReactionType
│   │   ├── comment_model.dart            # Comment model (flat collection)
│   │   ├── reply_model.dart              # Reply model (flat collection, max 1 nesting)
│   │   └── post_reaction_model.dart      # Individual user reaction document
│   └── repositories/
│       └── community_repository.dart      # All Firebase CRUD operations
├── features/community/
│   ├── controllers/
│   │   ├── create_post_controller.dart   # Post creation form state
│   │   ├── feed_controller.dart          # Feed list + pagination + reactions
│   │   └── post_detail_controller.dart   # Post detail + comments + replies
│   └── views/
│       ├── screens/
│       │   ├── create_post_screen.dart   # Full post creation screen
│       │   ├── feed_screen.dart          # Community feed with infinite scroll
│       │   ├── post_detail_screen.dart   # Full post + comments + reply threading
│       │   └── reaction_list_screen.dart # Who reacted (filterable by type)
│       └── widgets/
│           ├── feed_post_card.dart       # Individual post card in feed
│           └── feed_create_post_bar.dart # Quick-post bar at top of feed
├── core/
│   ├── bindings/initial_binding.dart     # CommunityRepository + FeedController registered
│   ├── services/cloud_functions_service.dart # Community function callers added
│   └── utils/constants/
│       └── firebase_paths.dart           # Community paths added (reactions, replies)
└── routes/
    ├── app_routes.dart                   # POST_DETAIL, REACTION_LIST routes added
    └── app_pages.dart                    # COMMUNITY, CREATE_POST pages registered

functions/src/
├── config/constants.ts                   # POSTS, COMMENTS, REPLIES, REACTIONS collections
├── types/index.ts                        # Community type interfaces added
├── features/community/
│   └── community-operations.ts           # 6 Cloud Functions
└── index.ts                              # Community exports added
```

---

## 🏗️ Architecture

```
┌──────────────────┐
│   UI Screens      │  → StatelessWidgets, Obx() for reactive state
│   + Widgets       │
└────────┬─────────┘
         │
┌────────▼─────────┐
│   Controllers     │  → GetxController, business logic, reactive vars
└────────┬─────────┘
         │
┌────────▼─────────┐
│   Repository      │  → CommunityRepository (Firestore, Storage, Auth)
└────────┬─────────┘
         │
┌────────▼─────────┐
│   Models          │  → fromFirestore(), toMap(), helper getters
└──────────────────┘
```

---

## 🔥 Firestore Data Model (Flat Collections)

### `posts/{postId}`
```json
{
  "postId": "abc123",
  "author": { "uid": "", "name": "", "photo": "" },
  "content": { "text": "...", "images": ["url1"] },
  "privacy": "public | friends | only_me",
  "status": "pending | approved | rejected",
  "reactionSummary": { "total": 5, "like": 3, "love": 2, ... },
  "commentCount": 10,
  "shareCount": 0,
  "isDeleted": false,
  "createdAt": Timestamp,
  "updatedAt": Timestamp
}
```

### `posts/{postId}/reactions/{userId}` (subcollection)
```json
{
  "userId": "",
  "postId": "",
  "reaction": "like | love | insightful | support | inspiring",
  "userName": "Display Name",
  "createdAt": Timestamp
}
```

### `comments/{commentId}` (top-level flat)
```json
{
  "commentId": "",
  "postId": "",
  "author": { "uid": "", "name": "", "photo": "" },
  "text": "...",
  "reactionSummary": { ... },
  "replyCount": 3,
  "isDeleted": false,
  "createdAt": Timestamp
}
```

### `replies/{replyId}` (top-level flat)
```json
{
  "replyId": "",
  "postId": "",
  "commentId": "",
  "author": { "uid": "", "name": "", "photo": "" },
  "text": "...",
  "isDeleted": false,
  "createdAt": Timestamp
}
```

---

## 🎯 Reaction System

### 5 Reaction Types
| Type | Emoji | Constant |
|------|-------|----------|
| Like | 👍 | `ReactionType.like` |
| Love | ❤️ | `ReactionType.love` |
| Insightful | 💡 | `ReactionType.insightful` |
| Support | 🤝 | `ReactionType.support` |
| Inspiring | 🔥 | `ReactionType.inspiring` |

### Toggle Behavior
- **Tap same reaction** → Remove reaction
- **Tap different reaction** → Switch to new type
- **First tap** → Add reaction
- **Optimistic UI** → Update locally, then sync server

---

## 📱 Screen Flows

### Create Post Flow
```
HomeScreen → CreatePostSection (tap "What's on your mind?")
  → CreatePostScreen
    → Type text + attach image + set privacy
    → Submit → Repository.createPost() → Get.back(result: true)
    → FeedController.refreshFeed()
```

### Feed → Detail Flow
```
FeedScreen → tap post card → PostDetailScreen(postId)
  → Shows full post + comments
  → Type comment → submitComment()
  → Tap "Reply" → startReply() → submitReply()
  → Tap reaction count → ReactionListScreen(postId, summary)
```

### Reaction Flow
```
FeedPostCard → tap Like button → toggleReaction(like)
  → Long press Like → Reaction popup overlay
    → Select from 5 emojis → toggleReaction(selected)
  → Optimistic update → server sync
```

---

## ☁️ Cloud Functions

| Function | Description | Auth |
|----------|-------------|------|
| `createCommunityPost` | Create new post | User |
| `togglePostReaction` | Add/update/remove reaction (transaction) | User |
| `addPostComment` | Add comment + increment counter | User |
| `addPostReply` | Add reply + increment counter | User |
| `moderatePost` | Approve/reject post | Admin/Mod |
| `deleteCommunityPost` | Soft delete (owner or admin) | User/Admin |

### Calling from Flutter
```dart
// Via CloudFunctionsService
await CloudFunctionsService.instance.createCommunityPost(
  text: 'Hello World',
  images: ['https://...'],
  privacy: 'public',
);

await CloudFunctionsService.instance.togglePostReaction(
  postId: 'abc123',
  reactionType: 'love',
);
```

---

## 🔗 Dependency Registration

### InitialBinding
```dart
// Repository - permanent
Get.put<CommunityRepository>(CommunityRepository(), permanent: true);

// Controller - lazy with fenix
Get.lazyPut<FeedController>(() => FeedController(), fenix: true);
```

### Screen-level Controllers
```dart
// CreatePostController - created in CreatePostScreen
final controller = Get.put(CreatePostController());

// PostDetailController - created in PostDetailScreen
final controller = Get.put(PostDetailController());
```

---

## 🛣️ Routes

| Route | Constant | Screen |
|-------|----------|--------|
| `/community` | `AppRoutes.COMMUNITY` | `FeedScreen` |
| `/create-post` | `AppRoutes.CREATE_POST` | `CreatePostScreen` |
| `/post-detail` | `AppRoutes.POST_DETAIL` | `PostDetailScreen` |
| `/reaction-list` | `AppRoutes.REACTION_LIST` | `ReactionListScreen` |

---

## 🔒 Privacy Model

| Privacy | Constant | Visibility |
|---------|----------|------------|
| Public | `PostPrivacy.public_` | Everyone |
| Friends | `PostPrivacy.friends` | Friends only |
| Only Me | `PostPrivacy.onlyMe` | Author only |

Privacy enforcement is handled by Firestore security rules (server-side).

---

## ⚡ Performance Patterns

1. **Progressive Loading**: Feed loads immediately, user reactions loaded in background batch
2. **Optimistic UI**: Reactions update locally before server confirmation
3. **Pagination**: 10 posts per page with cursor-based pagination
4. **CachedNetworkImage**: All post/avatar images cached
5. **Shimmer Loading**: Skeleton screens while feed loads
6. **Lazy Controllers**: FeedController uses `fenix: true` for re-creation

---

## 📋 Checklist for Future Enhancements

- [ ] Content moderation (AI text filtering in Cloud Functions)
- [ ] Report post functionality
- [ ] Share post (internal + external)
- [ ] Edit post
- [ ] Comment reactions
- [ ] Media gallery (multiple images in post)
- [ ] Video support
- [ ] Mention users (@username)
- [ ] Hashtag support
- [ ] Post search
- [ ] Notification on comment/reply
