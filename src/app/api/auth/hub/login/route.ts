import { db } from "@/db";
import { hubs } from "@/db/schema";
import { eq } from "drizzle-orm";
import { signToken, verifyPassword } from "@/lib/auth";

export const dynamic = "force-dynamic";

export async function POST(req: Request) {
  let body: any;
  try {
    body = await req.json();
  } catch {
    return Response.json({ error: "Invalid JSON" }, { status: 400 });
  }
  const adminEmail = String(body?.admin_email ?? "").trim().toLowerCase();
  const password = String(body?.password ?? "");
  if (!adminEmail || !password) {
    return Response.json({ error: "Email and password are required." }, { status: 400 });
  }

  const [hub] = await db.select().from(hubs).where(eq(hubs.adminEmail, adminEmail)).limit(1);
  if (!hub || !verifyPassword(password, hub.passwordHash)) {
    return Response.json({ error: "Invalid email or password." }, { status: 401 });
  }

  const token = signToken({ sub: hub.id, role: "hub" });
  return Response.json({
    ok: true,
    role: "hub",
    token,
    hub: { id: hub.id, name: hub.name, location: hub.location, admin_email: hub.adminEmail, wifi_ssid: hub.wifiSsid },
  });
}
