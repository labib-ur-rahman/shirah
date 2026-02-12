/**
 * SHIRAH Cloud Functions - Micro Job Module
 * =============================================
 * Handles micro job creation, listing, proof submission, and review.
 * 
 * Functions:
 * - createMicroJob        → Create a new micro job (debits wallet)
 * - getAvailableJobs      → List approved jobs for workers
 * - getMicroJobDetails     → Get full job details
 * - getMyCreatedJobs      → List jobs created by the user
 * - submitJobProof        → Submit proof for a job
 * - getMySubmissions      → List user's submissions
 * - reviewJobSubmission   → Approve/reject a submission (author/admin)
 * - adminReviewJob        → Approve/reject/pause a job (admin only)
 */

import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import {
  COLLECTIONS,
  TRANSACTION_TYPES,
  TRANSACTION_SOURCES,
  USER_ROLES,
  REGION,
} from "../../config/constants";
import {
  UserDocument,
  ApiResponse,
} from "../../types";
import {
  serverTimestamp,
  generateTransactionId,
  increment,
} from "../../utils/helpers";
import {
  validateAuthenticated,
  validateRequiredFields,
  validateUserAccountState,
  validatePositiveNumber,
  validateMinimumRole,
} from "../../utils/validators";
import { createAuditLog } from "../audit/audit-logging";
import { getUserByUid } from "../users/user-management";

const db = admin.firestore();

// ============================================
// CONSTANTS
// ============================================

const JOB_COLLECTIONS = {
  JOBS: "jobs",
  JOB_SUBMISSIONS: "job_submissions",
} as const;

const JOB_STATUS = {
  PENDING: "PENDING",
  APPROVED: "APPROVED",
  REJECTED: "REJECTED",
  PAUSED: "PAUSED",
  COMPLETED: "COMPLETED",
} as const;

const SUBMISSION_STATUS = {
  PENDING: "PENDING",
  APPROVED: "APPROVED",
  REJECTED: "REJECTED",
} as const;

const JOB_AUDIT_ACTIONS = {
  JOB_CREATE: "job.create",
  JOB_APPROVE: "job.approve",
  JOB_REJECT: "job.reject",
  JOB_PAUSE: "job.pause",
  JOB_RESUME: "job.resume",
  SUBMISSION_CREATE: "job_submission.create",
  SUBMISSION_APPROVE: "job_submission.approve",
  SUBMISSION_REJECT: "job_submission.reject",
} as const;

/** Service fee percentage (10%) */
const SERVICE_FEE_PERCENT = 10;

// ============================================
// MICRO JOB TYPES
// ============================================

interface CreateMicroJobRequest {
  title: string;
  details: string;
  coverImage: string;
  jobLink: string;
  limit: number;
  perUserPrice: number;
}

interface SubmitJobProofRequest {
  jobId: string;
  proofImages: string[];
  proofText: string;
}

interface ReviewSubmissionRequest {
  submissionId: string;
  action: "approve" | "reject";
  rejectionNote?: string;
}

interface AdminReviewJobRequest {
  jobId: string;
  action: "approve" | "reject" | "pause" | "resume";
  rejectionNote?: string;
}

// ============================================
// CREATE MICRO JOB
// ============================================

/**
 * Create a new micro job post.
 * 
 * Flow:
 * 1. Validate user is authenticated & verified
 * 2. Validate input fields
 * 3. Calculate totalPrice = (limit * perUserPrice) + 10% service fee
 * 4. Check wallet balance >= totalPrice
 * 5. Debit wallet atomically
 * 6. Create job document with status = PENDING
 * 7. Log wallet transaction + audit
 */
export const createMicroJob = functions.https.onCall(
  { region: REGION },
  async (
    request: functions.https.CallableRequest<CreateMicroJobRequest>
  ): Promise<ApiResponse> => {
    const uid = validateAuthenticated(request.auth);
    const data = request.data;

    // Validate required fields
    validateRequiredFields(data as any, [
      "title",
      "details",
      "coverImage",
      "jobLink",
      "limit",
      "perUserPrice",
    ]);

    // Validate numeric fields
    validatePositiveNumber(data.limit, "limit");
    validatePositiveNumber(data.perUserPrice, "perUserPrice");

    // Validate string lengths
    if (data.title.length < 5 || data.title.length > 200) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Title must be between 5 and 200 characters"
      );
    }
    if (data.details.length < 20 || data.details.length > 5000) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Details must be between 20 and 5000 characters"
      );
    }
    if (data.limit < 1 || data.limit > 10000) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Limit must be between 1 and 10,000"
      );
    }
    if (data.perUserPrice < 0.5 || data.perUserPrice > 1000) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Per user price must be between ৳0.5 and ৳1,000"
      );
    }

    // Get user
    const user = await getUserByUid(uid);
    if (!user) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }

    // Validate user state
    validateUserAccountState(user.status.accountState);

    // User must be verified to create jobs
    if (!user.status.verified) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "You must verify your profile before creating micro jobs"
      );
    }

    // Check wallet is not locked
    if (user.wallet.locked) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Your wallet is locked. Contact support."
      );
    }

    // Calculate pricing
    const basePrice = data.limit * data.perUserPrice;
    const serviceFee = Math.ceil(basePrice * (SERVICE_FEE_PERCENT / 100));
    const totalPrice = basePrice + serviceFee;

    // Check balance
    if (user.wallet.balanceBDT < totalPrice) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        `Insufficient balance. Required: ৳${totalPrice}, Available: ৳${user.wallet.balanceBDT}`
      );
    }

    // Create job and debit wallet atomically
    const jobRef = db.collection(JOB_COLLECTIONS.JOBS).doc();
    const walletTxRef = db.collection(COLLECTIONS.WALLET_TRANSACTIONS).doc();
    const authorName = `${user.identity.firstName} ${user.identity.lastName}`.trim();

    await db.runTransaction(async (tx) => {
      // Re-read user in transaction for consistency
      const userRef = db.collection(COLLECTIONS.USERS).doc(uid);
      const userDoc = await tx.get(userRef);
      const userData = userDoc.data() as UserDocument;

      if (userData.wallet.balanceBDT < totalPrice) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Insufficient balance"
        );
      }

      const balanceBefore = userData.wallet.balanceBDT;
      const balanceAfter = balanceBefore - totalPrice;

      // Create job document
      tx.set(jobRef, {
        jobId: jobRef.id,
        authorId: uid,
        authorName,
        title: data.title.trim(),
        details: data.details.trim(),
        coverImage: data.coverImage,
        jobLink: data.jobLink.trim(),
        limit: data.limit,
        perUserPrice: data.perUserPrice,
        totalPrice,
        serviceFee,
        submittedCount: 0,
        approvedCount: 0,
        status: JOB_STATUS.PENDING,
        rejectionNote: null,
        createdAt: serverTimestamp(),
        approvedAt: null,
      });

      // Debit wallet
      tx.update(userRef, {
        "wallet.balanceBDT": balanceAfter,
        "meta.updatedAt": serverTimestamp(),
      });

      // Log wallet transaction
      tx.set(walletTxRef, {
        id: generateTransactionId("WTX"),
        uid,
        type: TRANSACTION_TYPES.DEBIT,
        source: TRANSACTION_SOURCES.MICRO_JOB,
        amount: totalPrice,
        balanceBefore,
        balanceAfter,
        description: `Micro job creation: ${data.title.trim()}`,
        reference: jobRef.id,
        createdAt: serverTimestamp(),
      });
    });

    // Audit log
    await createAuditLog({
      actorUid: uid,
      actorRole: user.role,
      action: JOB_AUDIT_ACTIONS.JOB_CREATE,
      targetCollection: JOB_COLLECTIONS.JOBS,
      targetDocId: jobRef.id,
      metadata: {
        title: data.title,
        limit: data.limit,
        perUserPrice: data.perUserPrice,
        totalPrice,
        serviceFee,
      },
    });

    functions.logger.info(`📋 Micro job created: ${jobRef.id} by ${uid}`);

    return {
      success: true,
      message: "Micro job created successfully. Pending admin approval.",
      data: {
        jobId: jobRef.id,
        totalPrice,
        serviceFee,
      },
    };
  }
);

// ============================================
// GET AVAILABLE JOBS (For Workers)
// ============================================

/**
 * List approved micro jobs available for workers
 */
export const getAvailableJobs = functions.https.onCall(
  { region: REGION },
  async (
    request: functions.https.CallableRequest<{ limit?: number; lastJobId?: string }>
  ): Promise<ApiResponse> => {
    // Authenticate but uid not needed for listing
    validateAuthenticated(request.auth);
    const limit = request.data?.limit || 20;

    let query = db
      .collection(JOB_COLLECTIONS.JOBS)
      .where("status", "==", JOB_STATUS.APPROVED)
      .orderBy("createdAt", "desc")
      .limit(limit);

    // Pagination
    if (request.data?.lastJobId) {
      const lastDoc = await db
        .collection(JOB_COLLECTIONS.JOBS)
        .doc(request.data.lastJobId)
        .get();
      if (lastDoc.exists) {
        query = query.startAfter(lastDoc);
      }
    }

    const snapshot = await query.get();
    const jobs = snapshot.docs.map((doc) => doc.data());

    return {
      success: true,
      message: "Jobs retrieved",
      data: { jobs, hasMore: jobs.length === limit },
    };
  }
);

// ============================================
// GET MICRO JOB DETAILS
// ============================================

/**
 * Get full details of a micro job
 */
export const getMicroJobDetails = functions.https.onCall(
  { region: REGION },
  async (
    request: functions.https.CallableRequest<{ jobId: string }>
  ): Promise<ApiResponse> => {
    const uid = validateAuthenticated(request.auth);
    const { jobId } = request.data;

    if (!jobId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Job ID is required"
      );
    }

    const jobDoc = await db.collection(JOB_COLLECTIONS.JOBS).doc(jobId).get();
    if (!jobDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Job not found");
    }

    const job = jobDoc.data();

    // Check if user has already submitted
    const existingSubmission = await db
      .collection(JOB_COLLECTIONS.JOB_SUBMISSIONS)
      .where("jobId", "==", jobId)
      .where("workerId", "==", uid)
      .limit(1)
      .get();

    const hasSubmitted = !existingSubmission.empty;
    let submissionStatus: string | null = null;
    if (hasSubmitted) {
      submissionStatus = existingSubmission.docs[0].data().status;
    }

    return {
      success: true,
      message: "Job details retrieved",
      data: {
        ...job,
        hasSubmitted,
        submissionStatus,
      },
    };
  }
);

// ============================================
// GET MY CREATED JOBS
// ============================================

/**
 * List jobs created by the authenticated user
 */
export const getMyCreatedJobs = functions.https.onCall(
  { region: REGION },
  async (
    request: functions.https.CallableRequest<{ limit?: number }>
  ): Promise<ApiResponse> => {
    const uid = validateAuthenticated(request.auth);
    const limit = request.data?.limit || 20;

    const snapshot = await db
      .collection(JOB_COLLECTIONS.JOBS)
      .where("authorId", "==", uid)
      .orderBy("createdAt", "desc")
      .limit(limit)
      .get();

    const jobs = snapshot.docs.map((doc) => doc.data());

    return {
      success: true,
      message: "Your jobs retrieved",
      data: { jobs },
    };
  }
);

// ============================================
// SUBMIT JOB PROOF
// ============================================

/**
 * Submit proof of job completion.
 *
 * Rules:
 * - One submission per user per job
 * - Job must be APPROVED and accepting submissions
 * - Atomic increment of submittedCount
 */
export const submitJobProof = functions.https.onCall(
  { region: REGION },
  async (
    request: functions.https.CallableRequest<SubmitJobProofRequest>
  ): Promise<ApiResponse> => {
    const uid = validateAuthenticated(request.auth);
    const { jobId, proofImages, proofText } = request.data;

    // Validate input
    if (!jobId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Job ID is required"
      );
    }
    if (!proofImages || proofImages.length === 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "At least one proof image is required"
      );
    }
    if (proofImages.length > 5) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Maximum 5 proof images allowed"
      );
    }
    if (!proofText || proofText.trim().length < 5) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Proof message must be at least 5 characters"
      );
    }

    // Get user
    const user = await getUserByUid(uid);
    if (!user) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }
    validateUserAccountState(user.status.accountState);

    // Check for existing submission
    const existingSubmission = await db
      .collection(JOB_COLLECTIONS.JOB_SUBMISSIONS)
      .where("jobId", "==", jobId)
      .where("workerId", "==", uid)
      .limit(1)
      .get();

    if (!existingSubmission.empty) {
      throw new functions.https.HttpsError(
        "already-exists",
        "You have already submitted proof for this job"
      );
    }

    // Get and validate job
    const jobRef = db.collection(JOB_COLLECTIONS.JOBS).doc(jobId);
    const submissionRef = db.collection(JOB_COLLECTIONS.JOB_SUBMISSIONS).doc();
    const workerName = `${user.identity.firstName} ${user.identity.lastName}`.trim();

    await db.runTransaction(async (tx) => {
      const jobDoc = await tx.get(jobRef);
      if (!jobDoc.exists) {
        throw new functions.https.HttpsError("not-found", "Job not found");
      }

      const jobData = jobDoc.data()!;

      // Validate job state
      if (jobData.status !== JOB_STATUS.APPROVED) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "This job is not currently accepting submissions"
        );
      }
      if (jobData.submittedCount >= jobData.limit) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "This job has reached its submission limit"
        );
      }

      // Cannot submit own job
      if (jobData.authorId === uid) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "You cannot submit proof for your own job"
        );
      }

      // Create submission
      tx.set(submissionRef, {
        submissionId: submissionRef.id,
        jobId,
        jobAuthorId: jobData.authorId,
        workerId: uid,
        workerName,
        proofImages,
        proofText: proofText.trim(),
        status: SUBMISSION_STATUS.PENDING,
        rejectionNote: null,
        createdAt: serverTimestamp(),
        reviewedAt: null,
      });

      // Increment submitted count
      tx.update(jobRef, {
        submittedCount: increment(1),
      });

      // Auto-complete job when limit reached
      if (jobData.submittedCount + 1 >= jobData.limit) {
        tx.update(jobRef, {
          status: JOB_STATUS.COMPLETED,
        });
      }
    });

    // Audit
    await createAuditLog({
      actorUid: uid,
      actorRole: user.role,
      action: JOB_AUDIT_ACTIONS.SUBMISSION_CREATE,
      targetCollection: JOB_COLLECTIONS.JOB_SUBMISSIONS,
      targetDocId: submissionRef.id,
      metadata: { jobId, proofImageCount: proofImages.length },
    });

    functions.logger.info(
      `📸 Job proof submitted: ${submissionRef.id} for job ${jobId} by ${uid}`
    );

    return {
      success: true,
      message: "Proof submitted successfully",
      data: { submissionId: submissionRef.id },
    };
  }
);

// ============================================
// GET MY SUBMISSIONS
// ============================================

/**
 * Get submissions made by the authenticated user
 */
export const getMySubmissions = functions.https.onCall(
  { region: REGION },
  async (
    request: functions.https.CallableRequest<{ limit?: number }>
  ): Promise<ApiResponse> => {
    const uid = validateAuthenticated(request.auth);
    const limit = request.data?.limit || 20;

    const snapshot = await db
      .collection(JOB_COLLECTIONS.JOB_SUBMISSIONS)
      .where("workerId", "==", uid)
      .orderBy("createdAt", "desc")
      .limit(limit)
      .get();

    // Enrich submissions with job details
    const submissions = await Promise.all(
      snapshot.docs.map(async (doc) => {
        const submissionData = doc.data();
        
        // Fetch job details
        const jobDoc = await db
          .collection(JOB_COLLECTIONS.JOBS)
          .doc(submissionData.jobId)
          .get();
        
        const jobData = jobDoc.data();
        
        // Return clean serializable object
        return {
          submissionId: doc.id,
          jobId: submissionData.jobId,
          jobAuthorId: submissionData.jobAuthorId,
          workerId: submissionData.workerId,
          workerName: submissionData.workerName,
          proofImages: submissionData.proofImages || [],
          proofText: submissionData.proofText || "",
          status: submissionData.status,
          rejectionNote: submissionData.rejectionNote || null,
          createdAt: submissionData.createdAt,
          reviewedAt: submissionData.reviewedAt || null,
          jobTitle: jobData?.title || "Unknown Job",
          jobCoverImage: jobData?.coverImage || "",
          perUserPrice: jobData?.perUserPrice || 0,
        };
      })
    );

    return {
      success: true,
      message: "Your submissions retrieved",
      data: { submissions },
    };
  }
);

// ============================================
// REVIEW JOB SUBMISSION (Author / Admin)
// ============================================

/**
 * Approve or reject a job submission.
 * 
 * On approve:
 * - Update submission status → APPROVED
 * - Increment approvedCount  
 * - Credit worker wallet (+BDT)
 * - Credit reward points (+5)
 * - Log transactions + audit
 * 
 * On reject:
 * - Update submission status → REJECTED
 * - Decrement submittedCount (free the slot)
 * - Store rejection note
 */
export const reviewJobSubmission = functions.https.onCall(
  { region: REGION },
  async (
    request: functions.https.CallableRequest<ReviewSubmissionRequest>
  ): Promise<ApiResponse> => {
    const uid = validateAuthenticated(request.auth);
    const { submissionId, action, rejectionNote } = request.data;

    if (!submissionId || !action) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Submission ID and action are required"
      );
    }
    if (!["approve", "reject"].includes(action)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Action must be 'approve' or 'reject'"
      );
    }
    if (action === "reject" && (!rejectionNote || rejectionNote.length < 5)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Rejection note is required (min 5 chars)"
      );
    }

    // Get reviewer
    const reviewer = await getUserByUid(uid);
    if (!reviewer) {
      throw new functions.https.HttpsError("not-found", "Reviewer not found");
    }

    // Get submission
    const submissionRef = db
      .collection(JOB_COLLECTIONS.JOB_SUBMISSIONS)
      .doc(submissionId);
    const submissionDoc = await submissionRef.get();
    if (!submissionDoc.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "Submission not found"
      );
    }

    const submission = submissionDoc.data()!;

    if (submission.status !== SUBMISSION_STATUS.PENDING) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Submission has already been reviewed"
      );
    }

    // Permission check: Must be job author or admin+
    const isJobAuthor = submission.jobAuthorId === uid;
    const isAdmin = [
      USER_ROLES.SUPER_ADMIN,
      USER_ROLES.ADMIN,
    ].includes(reviewer.role as any);

    if (!isJobAuthor && !isAdmin) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only the job author or admins can review submissions"
      );
    }

    const jobRef = db.collection(JOB_COLLECTIONS.JOBS).doc(submission.jobId);

    if (action === "approve") {
      // Get job to know perUserPrice
      const jobDoc = await jobRef.get();
      if (!jobDoc.exists) {
        throw new functions.https.HttpsError("not-found", "Job not found");
      }
      const jobData = jobDoc.data()!;
      const rewardAmount = jobData.perUserPrice;
      const rewardPoints = 5; // Fixed reward points per job completion

      await db.runTransaction(async (tx) => {
        // Update submission
        tx.update(submissionRef, {
          status: SUBMISSION_STATUS.APPROVED,
          reviewedAt: serverTimestamp(),
        });

        // Increment approved count
        tx.update(jobRef, {
          approvedCount: increment(1),
        });

        // Credit worker wallet
        const workerRef = db.collection(COLLECTIONS.USERS).doc(submission.workerId);
        tx.update(workerRef, {
          "wallet.balanceBDT": increment(rewardAmount),
          "wallet.rewardPoints": increment(rewardPoints),
          "meta.updatedAt": serverTimestamp(),
        });

        // Log wallet transaction
        const walletTxRef = db.collection(COLLECTIONS.WALLET_TRANSACTIONS).doc();
        tx.set(walletTxRef, {
          id: generateTransactionId("WTX"),
          uid: submission.workerId,
          type: TRANSACTION_TYPES.CREDIT,
          source: TRANSACTION_SOURCES.MICRO_JOB,
          amount: rewardAmount,
          description: `Micro job reward: ${jobData.title}`,
          reference: submissionId,
          createdAt: serverTimestamp(),
        });

        // Log reward transaction
        const rewardTxRef = db.collection(COLLECTIONS.REWARD_TRANSACTIONS).doc();
        tx.set(rewardTxRef, {
          id: generateTransactionId("RPT"),
          uid: submission.workerId,
          type: TRANSACTION_TYPES.CREDIT,
          source: TRANSACTION_SOURCES.MICRO_JOB,
          points: rewardPoints,
          description: `Micro job completion bonus: ${jobData.title}`,
          reference: submissionId,
          createdAt: serverTimestamp(),
        });
      });

      await createAuditLog({
        actorUid: uid,
        actorRole: reviewer.role,
        action: JOB_AUDIT_ACTIONS.SUBMISSION_APPROVE,
        targetUid: submission.workerId,
        targetCollection: JOB_COLLECTIONS.JOB_SUBMISSIONS,
        targetDocId: submissionId,
        metadata: {
          jobId: submission.jobId,
          rewardAmount,
          rewardPoints,
        },
      });

    } else {
      // Reject
      await db.runTransaction(async (tx) => {
        tx.update(submissionRef, {
          status: SUBMISSION_STATUS.REJECTED,
          rejectionNote: rejectionNote || "",
          reviewedAt: serverTimestamp(),
        });

        // Decrement submitted count (free the slot)
        tx.update(jobRef, {
          submittedCount: increment(-1),
        });

        // If job was COMPLETED, revert to APPROVED (slot freed)
        const jobDoc = await tx.get(jobRef);
        if (jobDoc.data()?.status === JOB_STATUS.COMPLETED) {
          tx.update(jobRef, { status: JOB_STATUS.APPROVED });
        }
      });

      await createAuditLog({
        actorUid: uid,
        actorRole: reviewer.role,
        action: JOB_AUDIT_ACTIONS.SUBMISSION_REJECT,
        targetUid: submission.workerId,
        targetCollection: JOB_COLLECTIONS.JOB_SUBMISSIONS,
        targetDocId: submissionId,
        metadata: {
          jobId: submission.jobId,
          rejectionNote,
        },
      });
    }

    functions.logger.info(
      `🔍 Submission ${submissionId} ${action}d by ${uid}`
    );

    return {
      success: true,
      message: `Submission ${action}d successfully`,
    };
  }
);

// ============================================
// ADMIN REVIEW JOB (Approve / Reject / Pause)
// ============================================

/**
 * Admin-only: Approve, reject, or pause a micro job
 */
export const adminReviewJob = functions.https.onCall(
  { region: REGION },
  async (
    request: functions.https.CallableRequest<AdminReviewJobRequest>
  ): Promise<ApiResponse> => {
    const uid = validateAuthenticated(request.auth);
    const { jobId, action, rejectionNote } = request.data;

    if (!jobId || !action) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Job ID and action are required"
      );
    }

    // Validate admin role
    const admin_user = await getUserByUid(uid);
    if (!admin_user) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }
    validateMinimumRole(admin_user.role, USER_ROLES.ADMIN);

    const jobRef = db.collection(JOB_COLLECTIONS.JOBS).doc(jobId);
    const jobDoc = await jobRef.get();
    if (!jobDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Job not found");
    }

    const jobData = jobDoc.data()!;
    const updates: Record<string, unknown> = {};

    switch (action) {
      case "approve":
        if (jobData.status !== JOB_STATUS.PENDING) {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "Only pending jobs can be approved"
          );
        }
        updates.status = JOB_STATUS.APPROVED;
        updates.approvedAt = serverTimestamp();
        break;

      case "reject":
        if (!rejectionNote || rejectionNote.length < 5) {
          throw new functions.https.HttpsError(
            "invalid-argument",
            "Rejection note is required"
          );
        }
        updates.status = JOB_STATUS.REJECTED;
        updates.rejectionNote = rejectionNote;

        // Refund the author
        const refundAmount = jobData.totalPrice;
        const authorRef = db.collection(COLLECTIONS.USERS).doc(jobData.authorId);
        const walletTxRef = db.collection(COLLECTIONS.WALLET_TRANSACTIONS).doc();

        await db.runTransaction(async (tx) => {
          const authorDoc = await tx.get(authorRef);
          const authorData = authorDoc.data() as UserDocument;

          tx.update(authorRef, {
            "wallet.balanceBDT": increment(refundAmount),
            "meta.updatedAt": serverTimestamp(),
          });

          tx.set(walletTxRef, {
            id: generateTransactionId("WTX"),
            uid: jobData.authorId,
            type: TRANSACTION_TYPES.CREDIT,
            source: TRANSACTION_SOURCES.MICRO_JOB,
            amount: refundAmount,
            balanceBefore: authorData.wallet.balanceBDT,
            balanceAfter: authorData.wallet.balanceBDT + refundAmount,
            description: `Micro job refund (rejected): ${jobData.title}`,
            reference: jobId,
            createdAt: serverTimestamp(),
          });
        });
        break;

      case "pause":
        if (jobData.status !== JOB_STATUS.APPROVED) {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "Only approved jobs can be paused"
          );
        }
        updates.status = JOB_STATUS.PAUSED;
        break;

      case "resume":
        if (jobData.status !== JOB_STATUS.PAUSED) {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "Only paused jobs can be resumed"
          );
        }
        updates.status = JOB_STATUS.APPROVED;
        break;

      default:
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Action must be approve, reject, pause, or resume"
        );
    }

    await jobRef.update(updates);

    const auditAction = action === "approve"
      ? JOB_AUDIT_ACTIONS.JOB_APPROVE
      : action === "reject"
      ? JOB_AUDIT_ACTIONS.JOB_REJECT
      : action === "pause"
      ? JOB_AUDIT_ACTIONS.JOB_PAUSE
      : JOB_AUDIT_ACTIONS.JOB_RESUME;

    await createAuditLog({
      actorUid: uid,
      actorRole: admin_user.role,
      action: auditAction,
      targetUid: jobData.authorId,
      targetCollection: JOB_COLLECTIONS.JOBS,
      targetDocId: jobId,
      metadata: { action, rejectionNote },
    });

    functions.logger.info(`🛡️ Job ${jobId} ${action}d by admin ${uid}`);

    return {
      success: true,
      message: `Job ${action}d successfully`,
    };
  }
);

// ============================================
// GET JOB SUBMISSIONS (For Author / Admin)
// ============================================

/**
 * Get submissions for a specific job (author or admin only)
 */
export const getJobSubmissions = functions.https.onCall(
  { region: REGION },
  async (
    request: functions.https.CallableRequest<{
      jobId: string;
      status?: string;
      limit?: number;
    }>
  ): Promise<ApiResponse> => {
    const uid = validateAuthenticated(request.auth);
    const { jobId, status, limit: queryLimit } = request.data;

    if (!jobId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Job ID is required"
      );
    }

    // Verify permission
    const jobDoc = await db.collection(JOB_COLLECTIONS.JOBS).doc(jobId).get();
    if (!jobDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Job not found");
    }

    const jobData = jobDoc.data()!;
    const user = await getUserByUid(uid);
    if (!user) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }

    const isAuthor = jobData.authorId === uid;
    const isAdmin = [USER_ROLES.SUPER_ADMIN, USER_ROLES.ADMIN].includes(
      user.role as any
    );

    if (!isAuthor && !isAdmin) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only job author or admins can view submissions"
      );
    }

    let query: FirebaseFirestore.Query = db
      .collection(JOB_COLLECTIONS.JOB_SUBMISSIONS)
      .where("jobId", "==", jobId);

    if (status) {
      query = query.where("status", "==", status);
    }

    query = query.orderBy("createdAt", "desc").limit(queryLimit || 50);

    const snapshot = await query.get();
    
    // Return clean serializable objects
    const submissions = snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        submissionId: doc.id,
        jobId: data.jobId,
        jobAuthorId: data.jobAuthorId,
        workerId: data.workerId,
        workerName: data.workerName,
        proofImages: data.proofImages || [],
        proofText: data.proofText || "",
        status: data.status,
        rejectionNote: data.rejectionNote || null,
        createdAt: data.createdAt,
        reviewedAt: data.reviewedAt || null,
      };
    });

    return {
      success: true,
      message: "Submissions retrieved",
      data: { submissions },
    };
  }
);
