/**
 * Runtime environment sanity checks.
 * Call this at the top of your server entry points to catch misconfigurations early.
 */

const DEFAULT_SECRET = "seg-dev-secret-change-me-please-32+";

export function checkEnv() {
  const jwtSecret = process.env.JWT_SECRET;
  if (!jwtSecret) {
    // eslint-disable-next-line no-console
    console.error("[SEG ENV CHECK] JWT_SECRET is not set. Tokens will not verify across restarts.");
  } else if (jwtSecret === DEFAULT_SECRET) {
    // eslint-disable-next-line no-console
    console.warn("[SEG ENV CHECK] JWT_SECRET is set to the development default. This is fine for local testing but should be rotated in production.");
  } else if (jwtSecret.length < 16) {
    // eslint-disable-next-line no-console
    console.warn("[SEG ENV CHECK] JWT_SECRET is shorter than 16 characters. Consider using a longer, random value.");
  } else {
    // eslint-disable-next-line no-console
    console.log("[SEG ENV CHECK] JWT_SECRET present and looks reasonable.");
  }

  if (!process.env.DATABASE_URL) {
    // eslint-disable-next-line no-console
    console.error("[SEG ENV CHECK] DATABASE_URL is not set. Database connections will fail.");
  } else {
    // eslint-disable-next-line no-console
    console.log("[SEG ENV CHECK] DATABASE_URL present.");
  }
}
