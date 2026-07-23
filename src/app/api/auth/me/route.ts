import { db } from "@/db";
import { coordinators, hubs } from "@/db/schema";
import { eq } from "drizzle-orm";
import { verifyToken } from "@/lib/auth";
import { checkEnv } from "@/lib/env-check";

// Run env check once when this module loads (server-side only)
if (typeof window === "undefined") {
  checkEnv();
}

export const dynamic = "force-dynamic";

function bearer(req: Request) {
  const h = req.headers.get("authorization") ?? "";
  return h.startsWith("Bearer ") ? h.slice(7) : null;
}

export async function GET(req: Request) {
  const rawAuth = req.headers.get("authorization") ?? "";
  const token = bearer(req);
  // eslint-disable-next-line no-console
  console.log("[SEG /api/auth/me] auth header present:", !!rawAuth, "token length:", token?.length ?? 0, "starts with Bearer:", rawAuth.startsWith("Bearer "));
  const payload = verifyToken(token, true);
  if (!payload) {
    // eslint-disable-next-line no-console
    console.log("[SEG /api/auth/me] verification failed, raw token preview:", token ? `${token.slice(0, 24)}...` : "none");
    return Response.json({ error: "Not authenticated", debug: { authHeaderPresent: !!rawAuth, tokenLength: token?.length ?? 0, hasBearer: rawAuth.startsWith("Bearer ") } }, { status: 401 });
  }

  if (payload.role === "hub") {
    const [h] = await db.select().from(hubs).where(eq(hubs.id, payload.sub)).limit(1);
    if (!h) return Response.json({ error: "Hub not found" }, { status: 404 });
    return Response.json({
      role: "hub",
      user: { id: h.id, name: h.name, location: h.location, admin_email: h.adminEmail, wifi_ssid: h.wifiSsid },
    });
  }

  const rows = await db
    .select({
      id: coordinators.id,
      fullName: coordinators.fullName,
      phone: coordinators.phone,
      hubId: coordinators.hubId,
      hubName: hubs.name,
      hubLocation: hubs.location,
    })
    .from(coordinators)
    .innerJoin(hubs, eq(hubs.id, coordinators.hubId))
    .where(eq(coordinators.id, payload.sub))
    .limit(1);
  const c = rows[0];
  if (!c) return Response.json({ error: "Coordinator not found" }, { status: 404 });
  return Response.json({
    role: "coordinator",
    user: { id: c.id, full_name: c.fullName, phone: c.phone, hub_id: c.hubId, hub_name: c.hubName, hub_location: c.hubLocation },
  });
}
