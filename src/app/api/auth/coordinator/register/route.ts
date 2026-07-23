import { db } from "@/db";
import { coordinators, hubs } from "@/db/schema";
import { eq } from "drizzle-orm";
import { hashPassword, normalizePhone, signToken } from "@/lib/auth";

export const dynamic = "force-dynamic";

export async function POST(req: Request) {
  let body: any;
  try {
    body = await req.json();
  } catch {
    return Response.json({ error: "Invalid JSON" }, { status: 400 });
  }
  const fullName = String(body?.full_name ?? "").trim();
  const phone = normalizePhone(String(body?.phone ?? ""));
  const password = String(body?.password ?? "");
  const hubId = String(body?.hub_id ?? "").trim();

  if (!fullName || !phone || !password || !hubId) {
    return Response.json({ error: "Full name, phone, password and hub are required." }, { status: 400 });
  }
  if (password.length < 6) {
    return Response.json({ error: "Password must be at least 6 characters." }, { status: 400 });
  }

  const [hub] = await db.select({ id: hubs.id, name: hubs.name }).from(hubs).where(eq(hubs.id, hubId)).limit(1);
  if (!hub) return Response.json({ error: "Selected hub was not found." }, { status: 404 });

  const dup = await db.select({ id: coordinators.id }).from(coordinators).where(eq(coordinators.phone, phone)).limit(1);
  if (dup.length) return Response.json({ error: "That phone number is already registered." }, { status: 409 });

  const [row] = await db
    .insert(coordinators)
    .values({ fullName, phone, passwordHash: hashPassword(password), hubId: hub.id })
    .returning({ id: coordinators.id, fullName: coordinators.fullName, phone: coordinators.phone, hubId: coordinators.hubId });

  const token = signToken({ sub: row.id, role: "coordinator" });
  return Response.json(
    {
      ok: true,
      role: "coordinator",
      token,
      coordinator: { id: row.id, full_name: row.fullName, phone: row.phone, hub_id: row.hubId, hub_name: hub.name },
    },
    { status: 201 }
  );
}
