# Micro Job System - Flutter Implementation Guide

> **Feature:** Micro Jobs Platform  
> **Stack:** Flutter + GetX + Firebase (Firestore + Cloud Functions + Storage)  
> **Pattern:** MVC + Repository  
> **Version:** 1.0.0

---

## 📁 File Structure

```
lib/
├── data/
│   ├── models/micro_job/
│   │   ├── micro_job_model.dart          # MicroJobModel, JobStatus, JobType
│   │   └── job_submission_model.dart     # JobSubmissionModel, SubmissionStatus
│   └── repositories/
│       └── micro_job_repository.dart     # Firebase operations layer
├── features/micro_jobs/
│   ├── controllers/
│   │   ├── create_micro_job_controller.dart  # Job creation form management
│   │   └── micro_job_controller.dart         # Job listing, detail & proof
│   └── views/
│       ├── screens/
│       │   ├── create_micro_job_screen.dart   # Create job post UI
│       │   ├── micro_job_screen.dart          # 2-column grid listing
│       │   └── micro_job_detail_screen.dart   # Full job detail + submit
│       └── widgets/
│           ├── micro_job_grid_card.dart   # Compact card for grid
│           ├── micro_job_shimmer.dart     # Loading shimmer placeholder
│           └── job_proof_bottom_sheet.dart # Multi-image proof submission
functions/
└── src/features/micro-jobs/
    └── micro-job-operations.ts           # 9 Cloud Functions
```

---

## 🏗️ Architecture Flow

```
UI (Screens/Widgets)
    ↓
Controller (GetxController)
    ↓
Repository (Firebase calls)
    ↓
Cloud Functions (server-side validation + transactions)
    ↓
Firestore Collections: jobs, job_submissions, wallet_transactions, audit_logs
```

---

## 📊 Data Models

### MicroJobModel
- **Collection:** `jobs/{jobId}`
- **Key Fields:** jobId, authorId, authorName, title, details, coverImage, jobLink, jobType, limit, perUserPrice, totalPrice, serviceFee, submittedCount, approvedCount, status
- **Computed:** `remainingSlots`, `isAcceptingSubmissions`, `progress`
- **Enums:** `JobStatus` (PENDING, APPROVED, REJECTED, PAUSED, COMPLETED), `JobType` (6 types)

### JobSubmissionModel
- **Collection:** `job_submissions/{submissionId}`
- **Key Fields:** submissionId, jobId, jobAuthorId, workerId, workerName, proofImages (List), proofText, status, rejectionNote
- **Enum:** `SubmissionStatus` (PENDING, APPROVED, REJECTED)

---

## 🔥 Cloud Functions (9 endpoints)

| Function | Purpose |
|----------|---------|
| `createMicroJob` | Validates user, calculates 10% fee, debits wallet atomically |
| `getAvailableJobs` | Paginated approved jobs list |
| `getMicroJobDetails` | Job details + hasSubmitted check |
| `getMyCreatedJobs` | Jobs created by current user |
| `submitJobProof` | One per user, increments submittedCount, auto-completes at limit |
| `getMySubmissions` | Worker's submission history |
| `reviewJobSubmission` | Approve: credit wallet+rewards; Reject: decrement count |
| `adminReviewJob` | Approve/reject/pause/resume with refund on reject |
| `getJobSubmissions` | All submissions for a job (owner/admin) |

### Pricing Formula
```
basePrice = limit × perUserPrice
serviceFee = basePrice × 0.10 (10%)
totalPrice = basePrice + serviceFee
```
Total is deducted from user wallet on job creation.

---

## 🎮 Controllers

### CreateMicroJobController
- Form fields: title, details, jobLink, limit, perUserPrice
- Auto-calculates totalPrice (base + 10% fee) on limit/price change
- Image picker for cover image
- Job type selector (6 types)
- Verification check before submission
- Wallet balance display

### MicroJobController
- `fetchAvailableJobs()` with pagination
- `loadMoreJobs()` / `refreshJobs()`
- `loadJobDetails(jobId)` with submission check
- `pickProofImages()` (multi-select, max 5)
- `submitProof(jobId)` with image upload flow

---

## 🖥️ Screens

### CreateMicroJobScreen
- **Trigger:** "Job Post" button (purple/pink) in `create_post_section.dart`
- **Fields:** Job type selector, title, multi-line instructions, cover image picker, task link, limit input, per-user price input
- **Live Calculator:** Shows base price, 10% service fee, total deduction
- **Wallet Info:** Displays current wallet balance
- **Verification Warning:** Shows if user is not verified

### MicroJobScreen
- **Layout:** 2-column GridView with `MicroJobGridCard`
- **Features:** Pull-to-refresh, infinite scroll pagination, shimmer loading
- **Empty State:** Centered icon + message
- **Navigation:** Tap card → `MicroJobDetailScreen`

### MicroJobDetailScreen
- **Layout:** SliverAppBar with cover image + scrollable content
- **Sections:** Title + type badge, Stats row (per task / remaining / approved), Progress bar, "Open Task Link" button, Instructions, Job Info card
- **Bottom Bar States:**
  1. Already submitted → Green "Proof Submitted" banner with status
  2. Not accepting → Red "No longer accepting" banner
  3. Available → Green "Submit Proof & Earn" button → Opens `JobProofBottomSheet`

### JobProofBottomSheet
- **Image Grid:** Drag handle, up to 5 screenshots with add/remove
- **Message:** Optional text field (max 500 chars)
- **Submit:** Disabled until ≥1 image added, shows loading spinner

---

## 🔗 Wiring & Bindings

### InitialBinding (initial_binding.dart)
```dart
// Micro Job Repository
Get.put<MicroJobRepository>(MicroJobRepository(), permanent: true);

// Micro Job Controller
Get.lazyPut<MicroJobController>(() => MicroJobController(), fenix: true);
```

### Routes (app_routes.dart)
```dart
static const String MICRO_JOBS = '/micro-jobs';
static const String CREATE_MICRO_JOB = '/create-micro-job';
static const String JOB_DETAILS = '/job-details';
static const String MY_TASKS = '/my-tasks';
```

### Create Post Section (create_post_section.dart)
Job Post button now navigates:
```dart
onTap: () => Get.to(
  () => const CreateMicroJobScreen(),
  transition: Transition.rightToLeftWithFade,
);
```

---

## 🔒 Business Rules

1. **User must be verified** to create micro jobs
2. **Wallet balance** must cover totalPrice (base + 10% fee)
3. **One submission per user per job** — button hidden after submission
4. **Auto-complete:** Job status becomes COMPLETED when submittedCount reaches limit
5. **Reward Points:** 5 points per approved submission
6. **Refund:** Full totalPrice refunded if admin rejects the job
7. **Audit Logging:** All create/approve/reject actions logged

---

## 🎨 Design System

| Element | Value |
|---------|-------|
| Primary Accent | `#8B5CF6` (Purple) |
| Success | `#10B981` (Green) |
| Warning | `#F59E0B` (Amber) |
| Danger | `#EF4444` (Red) |
| Dark Background | `#0F0F1A` |
| Dark Card | `#1E1E2E` |
| Dark Surface | `#2A2A3E` |
| Font | Google Fonts - Hind Siliguri |
| Icons | Iconsax |
| Sizing | flutter_screenutil (.w, .h, .r, .sp) |

---

## ✅ Testing Checklist

- [ ] Create job with all fields → Verify wallet deduction
- [ ] Job appears in grid after admin approval
- [ ] Open task link → External browser
- [ ] Submit proof with 1-5 screenshots + message
- [ ] Second visit → "Proof Submitted" banner shown
- [ ] Job auto-completes at limit
- [ ] Admin approve/reject → Wallet credit/refund
- [ ] Empty state when no jobs
- [ ] Pull-to-refresh works
- [ ] Dark/Light mode consistency
