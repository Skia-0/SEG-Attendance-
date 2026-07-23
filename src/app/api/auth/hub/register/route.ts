import { db } from "@/db";
import { hubs } from "@/db/schema";
import { eq } from "drizzle-orm";
import { hashPassword, signToken } from "@/lib/auth";

export const dynamic = "force-dynamic";

const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export async function POST(req: Request) {
  let body: any;
  try {
    body = await req.json();
  } catch {
    return Response.json({ error: "Invalid JSON" }, { status: 400 });
  }
  const name = String(body?.name ?? "").trim();
  const location = String(body?.location ?? "").trim();
  const wifiSsid = String(body?.wifi_ssid ?? "").trim();
  const adminEmail = String(body?.admin_email ?? "").trim().toLowerCase();
  const password = String(body?.password ?? "");

  if (!name || !location || !adminEmail || !password) {
    return Response.json({ error: "Name, location, email and password are required." }, { status: 400 });
  }
  if (!EMAIL.test(adminEmail)) {
    return Response.json({ error: "Enter a valid admin email address." }, { status: 400 });
  }
  if (password.length < 6) {
    return Response.json({ error: "Password must be at least 6 characters." }, { status: 400 });
  }

  const existing = await db.select({ id: hubs.id }).from(hubs).where(eq(hubs.adminEmail, adminEmail)).limit(1);
  if (existing.length) {
    return Response.json({ error: "A hub is already registered with that email." }, { status: 409 });
  }

  const [row] = await db
    .insert(hubs)
    .values({
      name,
      location,
      wifiSsid: wifiSsid || null,
      adminEmail,
      passwordHash: hashPassword(password),
    })
    .returning({ id: hubs.id, name: hubs.name, location: hubs.location, adminEmail: hubs.adminEmail });

  const token = signToken({ sub: row.id, role: "hub" });
  return Response.json(
    {
      ok: true,
      role: "hub",
      token,
      hub: { id: row.id, name: row.name, location: row.location, admin_email: row.adminEmail },
    },
    { status: 201 }
  );
}
