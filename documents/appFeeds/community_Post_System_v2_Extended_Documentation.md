# Community Post, Reaction & Moderation System

## Production Reference Documentation (v2 Extended)

Platform: Flutter + Firebase (Firestore, Cloud Functions)\
Last Updated: 2026-02-11 08:30:30 UTC

------------------------------------------------------------------------

# 1. System Vision

This document serves as the single source of truth for the Community
Post System. It is designed for long-term scalability, maintainability,
moderation control, and full compliance with Google Play User Generated
Content policies.

This documentation is implementation-ready and future-proof.

------------------------------------------------------------------------

# 2. Core Architecture Principles

## 2.1 Flat Scalable Structure

-   No deep nested collections
-   Comments and replies stored in top-level collections
-   Optimized for high-scale environments

## 2.2 Server-Controlled Counters

All counters are updated via Cloud Functions only. Client cannot
directly modify counts.

Prevents: - Fake engagement - Race conditions - Data inconsistency

## 2.3 Lazy Loading Strategy

-   Feed loads minimal data
-   Comments load separately
-   Replies load on-demand
-   Reaction lists load only when tapped

## 2.4 Strict Enum Usage

Enums must remain identical across: - Flutter - Firestore - Cloud
Functions

------------------------------------------------------------------------

# 3. ENUM DEFINITIONS

## 3.1 PostStatus

PENDING\
APPROVED\
REJECTED

## 3.2 PostPrivacy

PUBLIC\
FRIENDS\
ONLY_ME

## 3.3 ReactionType (Updated)

LIKE 👍\
LOVE ❤️\
INSIGHTFUL 💡\
SUPPORT 🤝\
INSPIRING 🔥

All reactions are positive to ensure a healthy community environment.

------------------------------------------------------------------------

# 4. Firestore Data Model

## 4.1 Posts Collection

Path: /posts/{postId}

Fields: - postId - author { uid, name, photo } - content { text,
images\[\] } - privacy - status - reactionSummary - commentCount -
isDeleted - deletedAt - deletedBy - createdAt - updatedAt

### reactionSummary Structure

-   total
-   like
-   love
-   insightful
-   support
-   inspiring

------------------------------------------------------------------------

## 4.2 Post Reactions

Path: /posts/{postId}/reactions/{userId}

Fields: - userId - reaction - createdAt

One user = one reaction per post.

------------------------------------------------------------------------

## 4.3 Comments Collection

Path: /comments/{commentId}

Fields: - commentId - postId - author { uid, name, photo } - text -
reactionSummary - replyCount - isDeleted - deletedAt - deletedBy -
createdAt

------------------------------------------------------------------------

## 4.4 Comment Reactions

Path: /comments/{commentId}/reactions/{userId}

Same structure as post reactions.

------------------------------------------------------------------------

## 4.5 Replies Collection

Path: /replies/{replyId}

Fields: - replyId - postId - commentId - author - text - isDeleted -
deletedAt - deletedBy - createdAt

Rules: - Max nesting level = 1 - No reactions on replies

------------------------------------------------------------------------

# 5. Composite Index Requirements

## 5.1 Comments Index

Collection: comments\
Fields: - postId (ASC) - createdAt (DESC)

## 5.2 Replies Index

Collection: replies\
Fields: - commentId (ASC) - createdAt (DESC)

Ensures high-speed pagination at scale.

------------------------------------------------------------------------

# 6. Soft Delete System

Instead of deleting documents permanently:

Fields: - isDeleted = true - deletedAt = timestamp - deletedBy = uid

All queries must include: where isDeleted == false

Benefits: - Audit trail - Safe moderation - Data recovery - Analytics
integrity

------------------------------------------------------------------------

# 7. Report System (Play Policy Compliance)

## 7.1 Reports Collection

Path: /reports/{reportId}

Fields: - reportId - targetType (POST \| COMMENT \| REPLY) - targetId -
reportedBy - reason - description - status (PENDING \| REVIEWED \|
ACTION_TAKEN) - createdAt

Users must be able to report any content.

Admin dashboard filters: where status == PENDING

------------------------------------------------------------------------

# 8. Shadow Ban System

Users Collection addition:

moderation: - isShadowBanned - reason - updatedAt

Behavior: - Shadow banned users see their own content - Others cannot
see their content

Used for spam prevention and silent moderation.

------------------------------------------------------------------------

# 9. Content Filtering via Cloud Functions

Trigger: onCreate post or comment

Process: 1. Scan text 2. Detect banned keywords 3. Detect suspicious
links 4. Optional AI moderation

If violation detected: - Keep status PENDING OR - Auto REJECT with
moderation note

Ensures safe and policy-compliant platform.

------------------------------------------------------------------------

# 10. Cloud Functions Responsibilities

## 10.1 Post Reaction Handling

-   Adjust reaction counters using transaction

## 10.2 Comment Creation

-   Increment post.commentCount

## 10.3 Reply Creation

-   Increment comment.replyCount

## 10.4 Comment Reaction Handling

-   Update comment.reactionSummary

All logic must run server-side.

------------------------------------------------------------------------

# 11. Privacy Enforcement

Firestore Security Rules must enforce:

PUBLIC → everyone\
FRIENDS → followers only\
ONLY_ME → author only

Client-side filtering alone is not sufficient.

------------------------------------------------------------------------

# 12. Loading Strategy

Feed: - Load posts only - No comments auto-load

Comment Screen: - Load comments by postId - Load replies by commentId

Reaction List: - Load only when user taps counter

This minimizes read cost and improves performance.

------------------------------------------------------------------------

# 13. Scalability Strategy

-   Flat collections
-   Composite indexes
-   Server-managed counters
-   Lazy loading
-   Soft delete
-   Moderation tools

Designed to handle millions of reactions and comments.

------------------------------------------------------------------------

# 14. Compliance Checklist

Platform includes: - Admin moderation - Report mechanism - Content
filtering - Privacy control - Soft delete - No negative reactions - No
harassment vectors

Fully aligned with Google Play UGC policy guidelines.

------------------------------------------------------------------------

# 15. Final Architecture Summary

This system is: - Production-ready - Moderation-enabled -
Privacy-controlled - Cost-optimized - Scalable - Policy-compliant

It is built for long-term growth and safe community management.

------------------------------------------------------------------------

END OF DOCUMENTATION
