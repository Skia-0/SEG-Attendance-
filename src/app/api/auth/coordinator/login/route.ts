import { db } from "@/db";
import { coordinators, hubs } from "@/db/schema";
import { eq } from "drizzle-orm";
import { normalizePhone, signToken, verifyPassword } from "@/lib/auth";

export const dynamic = "force-dynamic";

export async function POST(req: Request) {
  let body: any;
  try {
    body = await req.json();
  } catch {
    return Response.json({ error: "Invalid JSON" }, { status: 400 });
  }
  const phone = normalizePhone(String(body?.phone ?? ""));
  const password = String(body?.password ?? "");
  if (!phone || !password) {
    return Response.json({ error: "Phone and password are required." }, { status: 400 });
  }

  const rows = await db
    .select({
      id: coordinators.id,
      fullName: coordinators.fullName,
      phone: coordinators.phone,
      passwordHash: coordinators.passwordHash,
      hubId: coordinators.hubId,
      hubName: hubs.name,
    })
    .from(coordinators)
    .innerJoin(hubs, eq(hubs.id, coordinators.hubId))
    .where(eq(coordinators.phone, phone))
    .limit(1);

  const c = rows[0];
  if (!c || !verifyPassword(password, c.passwordHash)) {
    return Response.json({ error: "Invalid phone or password." }, { status: 401 });
  }

  const token = signToken({ sub: c.id, role: "coordinator" });
  return Response.json({
    ok: true,
    role: "coordinator",
    token,
    coordinator: { id: c.id, full_name: c.fullName, phone: c.phone, hub_id: c.hubId, hub_name: c.hubName },
  });
}
