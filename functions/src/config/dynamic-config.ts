/**
 * SHIRAH Cloud Functions - Dynamic Configuration Service
 * ==========================================================
 *
 * All business rules are stored in Firestore `configurations/app_settings`
 * and fetched at runtime. Changes take effect without redeploying code.
 *
 * Cache Strategy:
 * - In-memory cache with 30-second TTL
 * - Ensures near-instant propagation of config changes
 * - Within a single function invocation, config is consistent
 * - Each new invocation (after TTL) gets fresh config
 *
 * Fallback:
 * - If Firestore document doesn't exist or a field is missing,
 *   DEFAULT_CONFIG values are used as fallback.
 */

import * as admin from "firebase-admin";

const db = admin.firestore();

// ============================================
// FIRESTORE LOCATION
// ============================================
export const CONFIG_COLLECTION = "configurations";
export const CONFIG_DOC_ID = "app_settings";

// ============================================
// CONFIGURATION INTERFACES
// ============================================

export interface InviteCodeConfig {
  prefix: string;
  suffix: string;
  randomLength: number;
  charset: string;
  totalLength: number;
}

export interface NetworkConfig {
  maxDepth: number;
  verificationDepth: number;
}

export interface RewardPointsConfig {
  conversionRate: number;
  minConversion: number;
  maxDailyConversions: number;
  maxWeeklyConversions: number;
  conversionFeePercent: number;
}

export interface AdsConfig {
  maxDailyAds: number;
  pointsPerAd: number;
  baseDailyPoints: number;
}

export interface StreakConfig {
  multipliers: Record<string, number>;
  maxMultiplier: number;
}

export interface LevelDistributionEntry {
  level: number;
  percent: number;
  points: number;
}

export interface SubscriptionConfig {
  priceBDT: number;
  rewardDistributedBDT: number;
  totalRewardPoints: number;
  levelDistribution: LevelDistributionEntry[];
}

export interface VerificationConfig {
  priceBDT: number;
  rewardDistributedBDT: number;
  totalRewardPoints: number;
  levelDistribution: LevelDistributionEntry[];
}

export interface WalletConfig {
  minWithdrawalBDT: number;
  withdrawalFeePer1000: number;
}

export interface UddoktaPayEnvironment {
  apiKey: string;
  panelURL: string;
  redirectURL: string;
  /** Cloud Function HTTP URL for UddoktaPay webhook (IPN) notifications */
  webhookURL: string;
}

export interface UddoktaPayConfig {
  isSandbox: boolean;
  sandbox: UddoktaPayEnvironment;
  production: UddoktaPayEnvironment;
  /** @deprecated Use sandbox/production objects instead. Kept for backward compatibility. */
  apiKey?: string;
  /** @deprecated Use sandbox/production objects instead. */
  panelURL?: string;
  /** @deprecated Use sandbox/production objects instead. */
  redirectURL?: string;
}

export interface AppConfig {
  network: NetworkConfig;
  inviteCode: InviteCodeConfig;
  rewardPoints: RewardPointsConfig;
  ads: AdsConfig;
  streak: StreakConfig;
  subscription: SubscriptionConfig;
  verification: VerificationConfig;
  wallet: WalletConfig;
  uddoktaPay: UddoktaPayConfig;
}

// ============================================
// DEFAULT VALUES (Fallback if Firestore is empty)
// These are the original hardcoded values
// ============================================

export const DEFAULT_CONFIG: AppConfig = {
  network: {
    maxDepth: 15,
    verificationDepth: 10,
  },

  inviteCode: {
    prefix: "S",
    suffix: "L",
    randomLength: 6,
    charset: "ABCDEFGHJKMNPQRSTUVWXYZ23456789",
    totalLength: 8,
  },

  rewardPoints: {
    conversionRate: 100, // 100 points = 1 BDT
    minConversion: 1000, // Minimum 1000 points (10 BDT)
    maxDailyConversions: 2,
    maxWeeklyConversions: 7,
    conversionFeePercent: 5, // 5% system fee
  },

  ads: {
    maxDailyAds: 20,
    pointsPerAd: 30,
    baseDailyPoints: 600, // 20 ads × 30 points
  },

  streak: {
    multipliers: {
      "1": 1.0, "2": 1.0,
      "3": 1.1, "4": 1.1,
      "5": 1.2, "6": 1.2,
      "7": 1.5, "8": 1.5, "9": 1.5,
      "10": 1.6, "11": 1.6,
      "12": 1.7, "13": 1.7,
      "14": 2.0, "15": 2.0,
      "16": 2.1, "17": 2.1,
      "18": 2.2, "19": 2.2,
      "20": 2.5, "21": 2.5,
      "22": 2.6, "23": 2.6,
      "24": 2.7, "25": 2.7,
      "26": 2.8, "27": 2.8,
      "28": 3.0, "29": 3.0, "30": 3.0,
    },
    maxMultiplier: 3.0,
  },

  subscription: {
    priceBDT: 400,
    rewardDistributedBDT: 240, // 60% of price
    totalRewardPoints: 24000, // 240 × 100
    levelDistribution: [
      { level: 1, percent: 25, points: 6000 },
      { level: 2, percent: 15, points: 3600 },
      { level: 3, percent: 10, points: 2400 },
      { level: 4, percent: 8, points: 1920 },
      { level: 5, percent: 7, points: 1680 },
      { level: 6, percent: 6, points: 1440 },
      { level: 7, percent: 5, points: 1200 },
      { level: 8, percent: 4, points: 960 },
      { level: 9, percent: 4, points: 960 },
      { level: 10, percent: 3, points: 720 },
      { level: 11, percent: 3, points: 720 },
      { level: 12, percent: 2, points: 480 },
      { level: 13, percent: 2, points: 480 },
      { level: 14, percent: 1.5, points: 360 },
      { level: 15, percent: 1.5, points: 360 },
    ],
  },

  verification: {
    priceBDT: 250,
    rewardDistributedBDT: 125, // 50% of price
    totalRewardPoints: 12500, // 125 × 100
    levelDistribution: [
      { level: 1, percent: 25, points: 3125 },
      { level: 2, percent: 15, points: 1875 },
      { level: 3, percent: 12, points: 1500 },
      { level: 4, percent: 10, points: 1250 },
      { level: 5, percent: 8, points: 1000 },
      { level: 6, percent: 7, points: 875 },
      { level: 7, percent: 6, points: 750 },
      { level: 8, percent: 6, points: 750 },
      { level: 9, percent: 6, points: 750 },
      { level: 10, percent: 5, points: 625 },
    ],
  },

  wallet: {
    minWithdrawalBDT: 100,
    withdrawalFeePer1000: 20, // 20 BDT per 1000
  },

  uddoktaPay: {
    isSandbox: true,
    sandbox: {
      apiKey: "",
      panelURL: "",
      redirectURL: "",
      webhookURL: "",
    },
    production: {
      apiKey: "",
      panelURL: "",
      redirectURL: "",
      webhookURL: "",
    },
  },
};

// ============================================
// IN-MEMORY CACHE
// ============================================

let cachedConfig: AppConfig | null = null;
let cacheTimestamp = 0;
const CACHE_TTL_MS = 30_000; // 30 seconds — change propagate within this window

// ============================================
// PUBLIC API
// ============================================

/**
 * Get application configuration from Firestore.
 *
 * Uses in-memory cache (30s TTL) to balance read cost vs freshness.
 * Merges Firestore data with DEFAULT_CONFIG to safely handle missing fields.
 *
 * @returns Complete AppConfig (from Firestore if available, else defaults)
 */
export async function getAppConfig(): Promise<AppConfig> {
  const now = Date.now();

  // Return cached config if still valid
  if (cachedConfig && (now - cacheTimestamp) < CACHE_TTL_MS) {
    return cachedConfig;
  }

  try {
    const doc = await db
      .collection(CONFIG_COLLECTION)
      .doc(CONFIG_DOC_ID)
      .get();

    if (!doc.exists) {
      // Config not seeded yet — use defaults
      cachedConfig = deepClone(DEFAULT_CONFIG);
    } else {
      const data = doc.data()!;
      cachedConfig = mergeWithDefaults(data);
    }
  } catch (error) {
    console.error("[DynamicConfig] Failed to fetch config, using defaults:", error);
    cachedConfig = deepClone(DEFAULT_CONFIG);
  }

  cacheTimestamp = now;
  return cachedConfig;
}

/**
 * Force-clear the in-memory config cache.
 * Call this after programmatic config updates so the next
 * `getAppConfig()` reads fresh data from Firestore.
 */
export function clearConfigCache(): void {
  cachedConfig = null;
  cacheTimestamp = 0;
}

// ============================================
// INTERNAL HELPERS
// ============================================

/**
 * Deep-merge Firestore doc fields with DEFAULT_CONFIG.
 * Each top-level section is spread; nested arrays (levelDistribution)
 * are taken from Firestore if present, else defaults.
 */
function mergeWithDefaults(data: Record<string, unknown>): AppConfig {
  const asSection = <T>(key: string): Partial<T> =>
    (data[key] as Partial<T>) || {};

  const subData = asSection<SubscriptionConfig>("subscription");
  const verData = asSection<VerificationConfig>("verification");
  const streakData = asSection<StreakConfig>("streak");

  return {
    network: {
      ...DEFAULT_CONFIG.network,
      ...asSection<NetworkConfig>("network"),
    },
    inviteCode: {
      ...DEFAULT_CONFIG.inviteCode,
      ...asSection<InviteCodeConfig>("inviteCode"),
    },
    rewardPoints: {
      ...DEFAULT_CONFIG.rewardPoints,
      ...asSection<RewardPointsConfig>("rewardPoints"),
    },
    ads: {
      ...DEFAULT_CONFIG.ads,
      ...asSection<AdsConfig>("ads"),
    },
    streak: {
      multipliers: {
        ...DEFAULT_CONFIG.streak.multipliers,
        ...(streakData.multipliers || {}),
      },
      maxMultiplier:
        streakData.maxMultiplier ?? DEFAULT_CONFIG.streak.maxMultiplier,
    },
    subscription: {
      ...DEFAULT_CONFIG.subscription,
      ...subData,
      levelDistribution:
        subData.levelDistribution || DEFAULT_CONFIG.subscription.levelDistribution,
    },
    verification: {
      ...DEFAULT_CONFIG.verification,
      ...verData,
      levelDistribution:
        verData.levelDistribution || DEFAULT_CONFIG.verification.levelDistribution,
    },
    wallet: {
      ...DEFAULT_CONFIG.wallet,
      ...asSection<WalletConfig>("wallet"),
    },
    uddoktaPay: mergeUddoktaPayConfig(asSection<UddoktaPayConfig>("uddoktaPay")),
  };
}

/**
 * Merge UddoktaPay config, supporting both legacy flat keys and new
 * sandbox/production structure for backward compatibility.
 */
function mergeUddoktaPayConfig(data: Partial<UddoktaPayConfig>): UddoktaPayConfig {
  const defaults = DEFAULT_CONFIG.uddoktaPay;

  // Support legacy flat-key format (apiKey, panelURL, redirectURL at root)
  const legacyApiKey = data.apiKey;
  const legacyPanelURL = data.panelURL;
  const legacyRedirectURL = data.redirectURL;

  const sandbox: UddoktaPayEnvironment = {
    ...defaults.sandbox,
    ...(data.sandbox || {}),
  };

  const production: UddoktaPayEnvironment = {
    ...defaults.production,
    ...(data.production || {}),
  };

  // If legacy flat keys exist and sandbox/production are empty, migrate them
  if (legacyApiKey && !sandbox.apiKey && !production.apiKey) {
    const isSandbox = data.isSandbox ?? defaults.isSandbox;
    if (isSandbox) {
      sandbox.apiKey = legacyApiKey;
      sandbox.panelURL = legacyPanelURL || sandbox.panelURL;
      sandbox.redirectURL = legacyRedirectURL || sandbox.redirectURL;
    } else {
      production.apiKey = legacyApiKey;
      production.panelURL = legacyPanelURL || production.panelURL;
      production.redirectURL = legacyRedirectURL || production.redirectURL;
    }
  }

  return {
    isSandbox: data.isSandbox ?? defaults.isSandbox,
    sandbox,
    production,
  };
}

/**
 * Simple deep clone (safe for JSON-serializable data).
 */
function deepClone<T>(obj: T): T {
  return JSON.parse(JSON.stringify(obj));
}
