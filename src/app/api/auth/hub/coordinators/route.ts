import { db } from "@/db";
import { coordinators } from "@/db/schema";
import { eq, count } from "drizzle-orm";
import { verifyToken } from "@/lib/auth";

export const dynamic = "force-dynamic";

export async function GET(req: Request) {
  const h = req.headers.get("authorization") ?? "";
  const token = h.startsWith("Bearer ") ? h.slice(7) : null;
  const payload = verifyToken(token);
  if (!payload || payload.role !== "hub") return Response.json({ error: "Hub access required" }, { status: 401 });

  const list = await db
    .select({ id: coordinators.id, fullName: coordinators.fullName, phone: coordinators.phone, createdAt: coordinators.createdAt })
    .from(coordinators)
    .where(eq(coordinators.hubId, payload.sub));

  const [{ total }] = await db.select({ total: count() }).from(coordinators).where(eq(coordinators.hubId, payload.sub));

  return Response.json({
    total,
    coordinators: list.map((c) => ({
      id: c.id,
      full_name: c.fullName,
      phone: c.phone,
      created_at: c.createdAt,
    })),
  });
}
