import {
  pgTable,
  uuid,
  text,
  timestamp,
  index,
  uniqueIndex,
} from "drizzle-orm/pg-core";
import { relations } from "drizzle-orm";

/**
 * SEG Attendance — data model
 * Mirrors the Flask backend (Hub + Coordinator + Cohort/Learner concepts) but
 * extends Hub with login credentials so both Hubs and Coordinators can
 * register and sign in from the web dashboard.
 */
export const hubs = pgTable(
  "hubs",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    name: text("name").notNull(),
    location: text("location").notNull(),
    wifiSsid: text("wifi_ssid").default(""),
    adminEmail: text("admin_email").notNull(),
    passwordHash: text("password_hash").notNull(),
    createdAt: timestamp("created_at", { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (t) => [uniqueIndex("hubs_admin_email_idx").on(t.adminEmail)]
);

export const coordinators = pgTable(
  "coordinators",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    fullName: text("full_name").notNull(),
    phone: text("phone").notNull(),
    passwordHash: text("password_hash").notNull(),
    hubId: uuid("hub_id")
      .notNull()
      .references(() => hubs.id, { onDelete: "cascade" }),
    createdAt: timestamp("created_at", { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (t) => [
    uniqueIndex("coordinators_phone_idx").on(t.phone),
    index("coordinators_hub_idx").on(t.hubId),
  ]
);

export const hubsRelations = relations(hubs, ({ many }) => ({
  coordinators: many(coordinators),
}));

export const coordinatorsRelations = relations(coordinators, ({ one }) => ({
  hub: one(hubs, { fields: [coordinators.hubId], references: [hubs.id] }),
}));

export type HubRow = typeof hubs.$inferSelect;
export type CoordinatorRow = typeof coordinators.$inferSelect;
