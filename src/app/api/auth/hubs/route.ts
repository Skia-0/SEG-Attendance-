import { db } from "@/db";
import { hubs } from "@/db/schema";
import { asc } from "drizzle-orm";

export const dynamic = "force-dynamic";

export async function GET() {
  const rows = await db.select({ id: hubs.id, name: hubs.name, location: hubs.location }).from(hubs).orderBy(asc(hubs.name));
  return Response.json({ hubs: rows.map((h) => ({ id: h.id, name: h.name, location: h.location })) });
}
