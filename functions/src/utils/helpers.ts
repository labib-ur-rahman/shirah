/**
 * SHIRAH Cloud Functions - Helper Utilities
 * Common helper functions used across all features
 */

import * as admin from "firebase-admin";
import { InviteCodeConfig, StreakConfig } from "../config/dynamic-config";

/**
 * Generate a unique invite code using dynamic config
 * Characters: ABCDEFGHJKMNPQRSTUVWXYZ23456789 (excluded O, I, l, 0, 1)
 */
export function generateInviteCode(config: InviteCodeConfig): string {
  const { prefix, suffix, randomLength, charset } = config;
  let randomPart = "";

  for (let i = 0; i < randomLength; i++) {
    const randomIndex = Math.floor(Math.random() * charset.length);
    randomPart += charset[randomIndex];
  }

  return `${prefix}${randomPart}${suffix}`;
}

/**
 * Validate invite code format using dynamic config
 */
export function isValidInviteCodeFormat(code: string, config: InviteCodeConfig): boolean {
  if (!code || code.length !== config.totalLength) {
    return false;
  }

  if (!code.startsWith(config.prefix) || !code.endsWith(config.suffix)) {
    return false;
  }

  const middle = code.substring(config.prefix.length, code.length - config.suffix.length);
  for (const char of middle) {
    if (!config.charset.includes(char)) {
      return false;
    }
  }

  return true;
}

/**
 * Get current server timestamp
 */
export function serverTimestamp(): FirebaseFirestore.FieldValue {
  return admin.firestore.FieldValue.serverTimestamp();
}

/**
 * Get current timestamp as Firestore Timestamp
 */
export function nowTimestamp(): FirebaseFirestore.Timestamp {
  return admin.firestore.Timestamp.now();
}

/**
 * Get today's date as ISO string (YYYY-MM-DD)
 */
export function getTodayDateString(): string {
  return new Date().toISOString().split("T")[0];
}

/**
 * Get streak multiplier for given day (dynamic config)
 */
export function getStreakMultiplier(day: number, streakConfig: StreakConfig): number {
  if (day <= 0) return 1.0;
  if (day > 30) return streakConfig.maxMultiplier;
  return streakConfig.multipliers[String(day)] ?? streakConfig.maxMultiplier;
}

/**
 * Calculate withdrawal fee (dynamic: feePer1000 BDT per 1000)
 */
export function calculateWithdrawalFee(amount: number, feePer1000: number): number {
  return Math.ceil(amount / 1000) * feePer1000;
}

/**
 * Hash sensitive data (like IP addresses)
 */
export function hashSensitiveData(data: string): string {
  const crypto = require("crypto");
  return crypto.createHash("sha256").update(data).digest("hex").substring(0, 16);
}

/**
 * Validate email format
 */
export function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

/**
 * Validate phone number (Bangladesh format)
 * Only accepts exactly 11 digits starting with "0" (e.g., 01602475999)
 * No country code prefix allowed
 */
export function isValidPhoneNumber(phone: string): boolean {
  if (!phone) return false;

  // Remove all non-numeric characters
  const numericOnly = phone.replace(/[^0-9]/g, "");

  // Only accept local format: 01XXXXXXXXX (exactly 11 digits, starts with 0)
  if (numericOnly.length !== 11) {
    return false;
  }

  return /^01[3-9]\d{8}$/.test(numericOnly);
}

/**
 * Sanitize string input
 */
export function sanitizeString(str: string): string {
  if (!str) return "";
  return str.trim().replace(/[<>]/g, "");
}

/**
 * Generate a unique transaction ID
 */
export function generateTransactionId(prefix: string = "TXN"): string {
  const timestamp = Date.now().toString(36).toUpperCase();
  const random = Math.random().toString(36).substring(2, 8).toUpperCase();
  return `${prefix}_${timestamp}_${random}`;
}

/**
 * Calculate date difference in days
 */
export function daysDifference(date1: Date, date2: Date): number {
  const diffTime = Math.abs(date2.getTime() - date1.getTime());
  return Math.floor(diffTime / (1000 * 60 * 60 * 24));
}

/**
 * Check if two dates are consecutive days
 */
export function areConsecutiveDays(date1: string, date2: string): boolean {
  const d1 = new Date(date1);
  const d2 = new Date(date2);
  const diff = daysDifference(d1, d2);
  return diff === 1;
}

/**
 * Check if date is today
 */
export function isToday(dateString: string): boolean {
  return dateString === getTodayDateString();
}

/**
 * Increment a Firestore field value
 */
export function increment(value: number): FirebaseFirestore.FieldValue {
  return admin.firestore.FieldValue.increment(value);
}

/**
 * Create empty level stats object
 */
export function createEmptyLevelStats(): { total: number; verified: number; subscribed: number } {
  return { total: 0, verified: 0, subscribed: 0 };
}

/**
 * Create initial network stats object (dynamic maxDepth)
 */
export function createInitialNetworkStats(maxDepth: number): Record<string, unknown> {
  const stats: Record<string, unknown> = {};
  for (let i = 1; i <= maxDepth; i++) {
    stats[`level${i}`] = createEmptyLevelStats();
  }
  stats.updatedAt = serverTimestamp();
  return stats;
}

/**
 * Get upline key for a level (u1, u2, ... uN) — dynamic maxDepth
 */
export function getUplineKey(level: number, maxDepth: number = 15): string {
  if (level < 1 || level > maxDepth) {
    throw new Error(`Invalid upline level: ${level}`);
  }
  return `u${level}`;
}

/**
 * Parse request data safely
 */
export function parseRequestData<T>(data: unknown): T {
  if (!data || typeof data !== "object") {
    throw new Error("Invalid request data");
  }
  return data as T;
}

/**
 * Format currency in BDT
 */
export function formatBDT(amount: number): string {
  return `৳${amount.toLocaleString("en-BD")}`;
}

/**
 * Format reward points
 */
export function formatPoints(points: number): string {
  return points.toLocaleString("en-BD");
}

/**
 * Sleep for specified milliseconds
 */
export function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Retry a function with exponential backoff
 */
export async function retryWithBackoff<T>(
  fn: () => Promise<T>,
  maxRetries: number = 3,
  initialDelay: number = 1000
): Promise<T> {
  let lastError: Error | undefined;

  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error as Error;
      if (attempt < maxRetries - 1) {
        const delay = initialDelay * Math.pow(2, attempt);
        await sleep(delay);
      }
    }
  }

  throw lastError;
}

/**
 * Check if user is active (logged in within 24 hours)
 */
export function isUserActive(lastActiveAt: FirebaseFirestore.Timestamp | null): boolean {
  if (!lastActiveAt) return false;
  const now = Date.now();
  const lastActive = lastActiveAt.toMillis();
  const hoursDiff = (now - lastActive) / (1000 * 60 * 60);
  return hoursDiff <= 24;
}

/**
 * Mask email for privacy
 */
export function maskEmail(email: string): string {
  const [local, domain] = email.split("@");
  if (local.length <= 2) {
    return `${local[0]}***@${domain}`;
  }
  return `${local[0]}${local[1]}***@${domain}`;
}

/**
 * Mask phone for privacy
 */
export function maskPhone(phone: string): string {
  if (phone.length < 6) return "***";
  return `${phone.substring(0, 3)}****${phone.substring(phone.length - 3)}`;
}
