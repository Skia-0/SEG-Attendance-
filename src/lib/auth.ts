import { createHmac, randomBytes, scryptSync, timingSafeEqual } from "node:crypto";

/**
 * Tiny dependency-free auth primitives:
 *  - scrypt password hashing (salt:hash, hex)
 *  - HS256 JWT-style signed tokens (no external lib)
 */

const SECRET = process.env.JWT_SECRET ?? "seg-dev-secret-change-me-please-32+";

function b64url(input: Buffer | string): string {
  const buf = typeof input === "string" ? Buffer.from(input) : input;
  return buf.toString("base64").replace(/=+$/g, "").replace(/\+/g, "-").replace(/\//g, "_");
}
function b64urlDecode(input: string): string {
  const pad = input.length % 4 === 0 ? "" : "=".repeat(4 - (input.length % 4));
  return Buffer.from(input.replace(/-/g, "+").replace(/_/g, "/") + pad, "base64").toString(
    "utf8"
  );
}

export function hashPassword(password: string): string {
  const salt = randomBytes(16);
  const hash = scryptSync(password, salt, 64);
  return `${salt.toString("hex")}:${hash.toString("hex")}`;
}

export function verifyPassword(password: string, stored: string): boolean {
  try {
    const [saltHex, hashHex] = stored.split(":");
    if (!saltHex || !hashHex) return false;
    const salt = Buffer.from(saltHex, "hex");
    const expected = Buffer.from(hashHex, "hex");
    const actual = scryptSync(password, salt, expected.length);
    if (actual.length !== expected.length) return false;
    return timingSafeEqual(actual, expected);
  } catch {
    return false;
  }
}

export type TokenPayload = {
  sub: string;
  role: "hub" | "coordinator";
  iat: number;
  exp: number;
};

export function signToken(payload: { sub: string; role: "hub" | "coordinator" }): string {
  const now = Math.floor(Date.now() / 1000);
  const body: TokenPayload = { ...payload, iat: now, exp: now + 60 * 60 * 24 * 7 };
  const header = b64url(JSON.stringify({ alg: "HS256", typ: "JWT" }));
  const data = b64url(JSON.stringify(body));
  const sig = createHmac("sha256", SECRET).update(`${header}.${data}`).digest();
  return `${header}.${data}.${b64url(sig)}`;
}

export function verifyToken(token: string | null | undefined, debug = false): TokenPayload | null {
  if (!token) {
    if (debug) console.log("[SEG verifyToken] no token provided");
    return null;
  }
  const parts = token.split(".");
  if (parts.length !== 3) {
    if (debug) console.log("[SEG verifyToken] invalid token format, parts:", parts.length);
    return null;
  }
  const [header, data, sig] = parts;
  const expected = b64url(
    createHmac("sha256", SECRET).update(`${header}.${data}`).digest()
  );
  if (expected !== sig) {
    if (debug) console.log("[SEG verifyToken] signature mismatch", { expected: expected.slice(0, 16), got: sig.slice(0, 16) });
    return null;
  }
  try {
    const payload = JSON.parse(b64urlDecode(data)) as TokenPayload;
    if (payload.exp < Math.floor(Date.now() / 1000)) {
      if (debug) console.log("[SEG verifyToken] token expired", new Date(payload.exp * 1000).toISOString());
      return null;
    }
    if (debug) console.log("[SEG verifyToken] token valid for role:", payload.role, "sub:", payload.sub.slice(0, 8));
    return payload;
  } catch (e) {
    if (debug) console.log("[SEG verifyToken] parse error", e);
    return null;
  }
}

export function passwordStrength(pw: string): { score: number; label: string } {
  let score = 0;
  if (pw.length >= 8) score++;
  if (/[A-Z]/.test(pw) && /[a-z]/.test(pw)) score++;
  if (/\d/.test(pw)) score++;
  if (/[^A-Za-z0-9]/.test(pw)) score++;
  const labels = ["Too weak", "Weak", "Fair", "Good", "Strong"];
  return { score, label: labels[score] };
}

export function normalizePhone(phone: string): string {
  return phone.replace(/[\s\-()]/g, "");
}
