"use client";
import type * as React from "react";
import { useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Logo } from "@/components/Logo";
import { Spinner, useToast } from "@/components/ui";
import {
  Building,
  Users,
  MapPin,
  Wifi,
  Mail,
  Phone,
  Nfc,
  Fingerprint,
  Clock,
  Logout,
  ArrowRight,
  Shield,
} from "@/components/icons";
import { clearSession, initials, readSession, type SessionUser } from "@/lib/session";

type HubMe = Extract<SessionUser, { role: "hub" }>;
type CoordMe = Extract<SessionUser, { role: "coordinator" }>;
type CoordRow = { id: string; full_name: string; phone: string; created_at: string };

export default function DashboardShell() {
  const router = useRouter();
  const toast = useToast();
  const [status, setStatus] = useState<"loading" | "ready" | "unauth">("loading");
  const [role, setRole] = useState<"hub" | "coordinator" | null>(null);
  const [me, setMe] = useState<SessionUser | null>(null);
  const [coords, setCoords] = useState<CoordRow[]>([]);
  const [coordTotal, setCoordTotal] = useState<number | null>(null);

  useEffect(() => {
    const s = readSession();
    // eslint-disable-next-line no-console
    console.log("[SEG Dashboard] readSession:", s ? { tokenLen: s.token.length, role: s.role, hasUser: !!s.user } : "null");
    if (!s) {
      // eslint-disable-next-line no-console
      console.log("[SEG Dashboard] no session found, redirecting to login");
      router.replace("/auth?mode=login");
      return;
    }
    setRole(s.role);
    fetch("/api/auth/me", { headers: { authorization: `Bearer ${s.token}` } })
      .then(async (r) => {
        const text = await r.text();
        let data: any = {};
        try { data = JSON.parse(text); } catch {}
        // eslint-disable-next-line no-console
        console.log("[SEG Dashboard] /api/auth/me response:", r.status, data);
        if (r.status === 401) {
          const debugInfo = data?.debug ? JSON.stringify(data.debug) : "";
          throw new Error(`unauth:${debugInfo}`);
        }
        if (!r.ok) throw new Error(`bad:${r.status}`);
        return JSON.parse(text);
      })
      .then((d) => {
        setMe(d.user as SessionUser);
        setRole(d.role);
        setStatus("ready");
        if (d.role === "hub") {
          fetch("/api/auth/hub/coordinators", { headers: { authorization: `Bearer ${s.token}` } })
            .then((r) => r.json())
            .then((c) => {
              setCoords(c.coordinators ?? []);
              setCoordTotal(typeof c.total === "number" ? c.total : (c.coordinators ?? []).length);
            })
            .catch(() => {});
        }
      })
      .catch((err) => {
        // eslint-disable-next-line no-console
        console.error("[SEG Dashboard] auth check failed:", err);
        const msg = err?.message ?? "";
        if (msg.startsWith("unauth")) {
          const debugPart = msg.split(":")[1] || "";
          clearSession();
          toast({
            type: "error",
            title: "Token verification failed",
            desc: debugPart ? `Server debug: ${debugPart}. Please sign in again.` : "Please sign in again.",
          });
          router.replace("/auth?mode=login");
        } else {
          setStatus("unauth");
        }
      });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  function logout() {
    clearSession();
    toast({ type: "info", title: "Signed out", desc: "See you next session." });
    router.replace("/auth?mode=login");
  }

  if (status === "loading") {
    return (
      <div className="grid min-h-screen place-items-center bg-ink text-paper">
        <div className="flex flex-col items-center gap-4">
          <div className="text-[40px]"><Logo tone="light" animated /></div>
          <Spinner className="h-7 w-7 text-brand" />
          <p className="text-sm text-white/50">Loading your dashboard…</p>
        </div>
      </div>
    );
  }

  if (!me) {
    return (
      <div className="grid min-h-screen place-items-center px-6">
        <div className="max-w-sm text-center">
          <h1 className="font-display text-2xl font-extrabold">Couldn't load your account</h1>
          <p className="mt-2 text-ink/60">Your session may have expired.</p>
          <Link href="/auth?mode=login" className="mt-5 inline-flex rounded-full bg-brand px-5 py-2.5 font-bold text-[#1a0f02]">Sign in</Link>
        </div>
      </div>
    );
  }

  const displayName = me.role === "hub" ? me.name : me.full_name;

  return (
    <div className="relative min-h-screen bg-paper text-ink">
      <div className="pointer-events-none absolute inset-0 -z-10">
        <div className="absolute inset-0 bg-dots opacity-40" />
        <div className="absolute -right-32 -top-32 h-[420px] w-[420px] rounded-full glow-brand opacity-50" />
      </div>

      {/* top bar */}
      <header className="sticky top-0 z-40 border-b border-white/10 bg-ink text-paper">
        <div className="mx-auto flex max-w-7xl items-center justify-between px-5 py-3 sm:px-8">
          <Link href="/" className="text-[26px] sm:text-[28px]"><Logo tone="light" /></Link>
          <div className="flex items-center gap-3">
            <div className="hidden text-right sm:block">
              <p className="text-sm font-semibold leading-tight">{displayName}</p>
              <p className="text-[0.7rem] uppercase tracking-[0.14em] text-brand-300">{me.role === "hub" ? "Hub admin" : "Coordinator"}</p>
            </div>
            <span className="grid h-10 w-10 place-items-center rounded-full bg-brand font-display text-sm font-extrabold text-[#1a0f02]">
              {initials(displayName)}
            </span>
            <button
              onClick={logout}
              className="inline-flex items-center gap-1.5 rounded-full border border-white/15 px-3.5 py-2 text-sm font-semibold text-white/80 transition-colors hover:border-white/30 hover:text-white"
            >
              <Logout className="h-4 w-4" /> <span className="hidden sm:inline">Sign out</span>
            </button>
          </div>
        </div>
      </header>

      <main className="mx-auto max-w-7xl px-5 py-10 sm:px-8 lg:py-14">
        {/* greeting */}
        <div className="flex flex-wrap items-end justify-between gap-4">
          <div>
            <p className="text-sm font-semibold uppercase tracking-[0.2em] text-brand-700">Dashboard</p>
            <h1 className="mt-2 font-display text-[clamp(2rem,4.6vw,3.2rem)] font-extrabold leading-[1] tracking-tight">
              Karibu, <span className="text-brand">{displayName.split(" ")[0]}</span>.
            </h1>
            <p className="mt-2 text-ink/60">
              {me.role === "hub"
                ? `Here's what's happening across ${me.name}.`
                : `You're signed in at ${(me as CoordMe).hub_name}.`}
            </p>
          </div>
          <span className="inline-flex items-center gap-2 rounded-full border border-palm/30 bg-palm/10 px-3 py-1.5 text-xs font-semibold text-palm">
            <span className="h-2 w-2 rounded-full bg-palm anim-pulse-glow" /> live session link active
          </span>
        </div>

        {me.role === "hub" ? (
          <HubView me={me as HubMe} coords={coords} coordTotal={coordTotal} />
        ) : (
          <CoordView me={me as CoordMe} toast={toast} />
        )}

        <MobileWorkflows />
      </main>

      <footer className="border-t border-ink/8 py-6 text-center text-xs text-ink/40">
        SEG Attendance · Social Enterprise Ghana
      </footer>
    </div>
  );
}

function HubView({ me, coords, coordTotal }: { me: HubMe; coords: CoordRow[]; coordTotal: number | null }) {
  return (
    <div className="mt-10 grid gap-6 lg:grid-cols-[1.3fr_1fr]">
      {/* identity */}
      <section className="relative overflow-hidden rounded-[1.8rem] bg-ink p-7 text-paper sm:p-9">
        <div className="pointer-events-none absolute inset-0 bg-grid-ink opacity-60" />
        <div className="pointer-events-none absolute -right-10 -top-10 h-56 w-56 rounded-full glow-brand anim-pulse-glow opacity-70" />
        <div className="relative">
          <div className="flex items-center gap-3">
            <span className="grid h-12 w-12 place-items-center rounded-2xl bg-brand text-[#1a0f02]"><Building className="h-6 w-6" /></span>
            <div>
              <p className="text-[0.7rem] uppercase tracking-[0.2em] text-white/50">Hub profile</p>
              <h2 className="font-display text-2xl font-extrabold leading-tight">{me.name}</h2>
            </div>
          </div>
          <dl className="mt-7 grid gap-4 sm:grid-cols-2">
            <Meta icon={<MapPin className="h-4 w-4" />} label="Location" value={me.location} />
            <Meta icon={<Mail className="h-4 w-4" />} label="Admin email" value={me.admin_email} />
            <Meta icon={<Wifi className="h-4 w-4" />} label="Wi‑Fi SSID" value={me.wifi_ssid || "— not set —"} />
            <Meta icon={<Shield className="h-4 w-4" />} label="Hub ID" value={<span className="font-mono text-xs">{me.id}</span>} />
          </dl>
        </div>
      </section>

      {/* stats */}
      <section className="grid grid-cols-2 gap-4">
        <Tile n={coordTotal ?? "—"} label="Coordinators" icon={<Users className="h-5 w-5" />} accent />
        <Tile n="86%" label="Avg presence" icon={<Clock className="h-5 w-5" />} tag="pilot" />
        <Tile n="12" label="Sessions / wk" icon={<Clock className="h-5 w-5" />} tag="pilot" />
        <Tile n="4" label="Active cohorts" icon={<Users className="h-5 w-5" />} tag="pilot" />
      </section>

      {/* coordinators list */}
      <section className="rounded-[1.8rem] border border-ink/8 bg-white p-6 sm:p-7 lg:col-span-2">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <h3 className="font-display text-xl font-extrabold">Coordinators on your roster</h3>
            <p className="text-sm text-ink/55">{coordTotal ?? 0} registered under {me.name}</p>
          </div>
          <Link href="/auth?mode=register&role=coordinator" className="inline-flex items-center gap-1.5 rounded-full bg-ink px-4 py-2 text-sm font-semibold text-paper transition-transform hover:-translate-y-0.5">
            Add coordinator <ArrowRight className="h-4 w-4" />
          </Link>
        </div>

        {coords.length === 0 ? (
          <div className="mt-6 grid place-items-center rounded-2xl border border-dashed border-ink/15 bg-paper-2/50 px-6 py-12 text-center">
            <span className="grid h-12 w-12 place-items-center rounded-2xl bg-brand/15 text-brand-700"><Users className="h-6 w-6" /></span>
            <p className="mt-3 font-display text-lg font-bold">No coordinators yet</p>
            <p className="mt-1 max-w-xs text-sm text-ink/55">Coordinators register with their phone and select this hub. Share the sign‑up link to get started.</p>
            <Link href="/auth?mode=register&role=coordinator" className="mt-4 inline-flex items-center gap-1.5 rounded-full bg-brand px-4 py-2 text-sm font-bold text-[#1a0f02]">
              Register the first coordinator <ArrowRight className="h-4 w-4" />
            </Link>
          </div>
        ) : (
          <ul className="mt-5 divide-y divide-ink/8">
            {coords.map((c) => (
              <li key={c.id} className="flex items-center gap-3 py-3.5">
                <span className="grid h-10 w-10 place-items-center rounded-full bg-ink font-display text-sm font-bold text-brand-300">{initials(c.full_name)}</span>
                <div className="min-w-0 flex-1">
                  <p className="truncate font-semibold">{c.full_name}</p>
                  <p className="flex items-center gap-1.5 text-xs text-ink/50"><Phone className="h-3.5 w-3.5" /> {c.phone}</p>
                </div>
                <span className="hidden text-xs text-ink/40 sm:block">joined {relDate(c.created_at)}</span>
                <span className="rounded-full bg-palm/12 px-2.5 py-1 text-[0.7rem] font-semibold text-palm">active</span>
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  );
}

function CoordView({ me, toast }: { me: CoordMe; toast: (t: any) => void }) {
  return (
    <div className="mt-10 grid gap-6 lg:grid-cols-[1.2fr_1fr]">
      <section className="relative overflow-hidden rounded-[1.8rem] bg-ink p-7 text-paper sm:p-9">
        <div className="pointer-events-none absolute inset-0 bg-grid-ink opacity-60" />
        <div className="pointer-events-none absolute -right-10 -top-10 h-56 w-56 rounded-full glow-brand anim-pulse-glow opacity-70" />
        <div className="relative">
          <div className="flex items-center gap-3">
            <span className="grid h-12 w-12 place-items-center rounded-2xl bg-brand text-[#1a0f02]"><Users className="h-6 w-6" /></span>
            <div>
              <p className="text-[0.7rem] uppercase tracking-[0.2em] text-white/50">Coordinator</p>
              <h2 className="font-display text-2xl font-extrabold leading-tight">{me.full_name}</h2>
            </div>
          </div>
          <dl className="mt-7 grid gap-4 sm:grid-cols-2">
            <Meta icon={<Phone className="h-4 w-4" />} label="Phone (username)" value={me.phone} />
            <Meta icon={<Building className="h-4 w-4" />} label="Hub" value={me.hub_name} />
            <Meta icon={<MapPin className="h-4 w-4" />} label="Hub location" value={me.hub_location ?? "—"} />
            <Meta icon={<Shield className="h-4 w-4" />} label="Coordinator ID" value={<span className="font-mono text-xs">{me.id}</span>} />
          </dl>
        </div>
      </section>

      <section className="grid grid-cols-2 gap-4">
        <Tile n="24" label="Learners today" icon={<Users className="h-5 w-5" />} tag="preview" />
        <Tile n="7" label="Day streak" icon={<Clock className="h-5 w-5" />} tag="preview" />
      </section>

      <section className="relative overflow-hidden rounded-[1.8rem] border border-brand/25 bg-gradient-to-br from-brand-100 to-paper p-7 lg:col-span-2">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.2em] text-brand-700">Next session</p>
            <h3 className="mt-1 font-display text-2xl font-extrabold">Morning cohort · {me.hub_name}</h3>
            <p className="mt-1 text-sm text-ink/60">Open check-in from the SEG mobile app to start capturing NFC & fingerprint taps.</p>
          </div>
          <button
            onClick={() => toast({ type: "info", title: "Open check-in on the app", desc: "Session controls live in the Flutter coordinator app." })}
            className="inline-flex items-center gap-2 rounded-full bg-ink px-5 py-3 font-bold text-paper transition-transform hover:-translate-y-0.5"
          >
            <Clock className="h-5 w-5 text-brand" /> Open check-in
          </button>
        </div>
        <div className="mt-6 flex flex-wrap gap-2.5">
          <Chip icon={<Nfc className="h-4 w-4" />} label="NFC tap‑in ready" />
          <Chip icon={<Fingerprint className="h-4 w-4" />} label="Fingerprint ready" />
          <Chip icon={<Shield className="h-4 w-4" />} label="Encrypted session token" />
        </div>
      </section>
    </div>
  );
}

function MobileWorkflows() {
  return (
    <section className="mt-6 rounded-[1.8rem] border border-ink/8 bg-white p-6 sm:p-8">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h3 className="font-display text-xl font-extrabold">On the floor: the mobile app</h3>
          <p className="text-sm text-ink/55">Coordinators run sessions from the Flutter app — this dashboard is the web half of the same system.</p>
        </div>
        <a
          href="https://github.com/Skia-0/seg-attendance-merged"
          target="_blank"
          rel="noreferrer"
          className="inline-flex items-center gap-1.5 rounded-full border border-ink/15 px-4 py-2 text-sm font-semibold transition-colors hover:border-ink/30"
        >
          View source <ArrowRight className="h-4 w-4" />
        </a>
      </div>
      <div className="mt-6 grid gap-4 sm:grid-cols-3">
        {[
          { i: <Nfc className="h-5 w-5" />, t: "NFC check‑in", d: "Learners tap a tag; UID matched to their SEG‑ id." },
          { i: <Fingerprint className="h-5 w-5" />, t: "Fingerprint", d: "Biometric scan marks presence without a card." },
          { i: <Clock className="h-5 w-5" />, t: "Open / close", d: "Start and end a session; totals feed certification." },
        ].map((f) => (
          <div key={f.t} className="rounded-2xl border border-ink/8 bg-paper-2/40 p-5 transition-transform hover:-translate-y-1">
            <span className="grid h-10 w-10 place-items-center rounded-xl bg-ink text-brand">{f.i}</span>
            <p className="mt-3 font-display text-base font-bold">{f.t}</p>
            <p className="mt-1 text-sm text-ink/60">{f.d}</p>
          </div>
        ))}
      </div>
    </section>
  );
}

/* ---------- small bits ---------- */
function Meta({ icon, label, value }: { icon: React.ReactNode; label: string; value: React.ReactNode }) {
  return (
    <div className="rounded-2xl border border-white/10 bg-white/[0.04] p-3.5">
      <p className="flex items-center gap-1.5 text-[0.68rem] uppercase tracking-[0.14em] text-white/45">
        <span className="text-brand-300">{icon}</span> {label}
      </p>
      <p className="mt-1 truncate text-sm font-semibold text-white/90">{value}</p>
    </div>
  );
}

function Tile({ n, label, icon, accent, tag }: { n: React.ReactNode; label: string; icon: React.ReactNode; accent?: boolean; tag?: string }) {
  return (
    <div className={`relative overflow-hidden rounded-2xl p-5 ${accent ? "bg-brand text-[#1a0f02]" : "border border-ink/8 bg-white"}`}>
      <div className="flex items-center justify-between">
        <span className={`grid h-9 w-9 place-items-center rounded-xl ${accent ? "bg-[#1a0f02]/10" : "bg-brand/12 text-brand-700"}`}>{icon}</span>
        {tag && <span className={`rounded-full px-2 py-0.5 text-[0.6rem] font-semibold uppercase tracking-wide ${accent ? "bg-[#1a0f02]/10" : "bg-ink/5 text-ink/45"}`}>{tag}</span>}
      </div>
      <p className="mt-4 font-display text-3xl font-extrabold tabular-nums">{n}</p>
      <p className={`text-xs ${accent ? "text-[#1a0f02]/70" : "text-ink/55"}`}>{label}</p>
    </div>
  );
}

function Chip({ icon, label }: { icon: React.ReactNode; label: string }) {
  return (
    <span className="inline-flex items-center gap-1.5 rounded-full border border-ink/10 bg-white px-3 py-1.5 text-xs font-semibold text-ink/70">
      <span className="text-brand-700">{icon}</span> {label}
    </span>
  );
}

function relDate(iso: string) {
  const d = new Date(iso).getTime();
  if (Number.isNaN(d)) return "recently";
  const diff = Date.now() - d;
  const days = Math.floor(diff / 86400000);
  if (days <= 0) return "today";
  if (days === 1) return "yesterday";
  if (days < 30) return `${days}d ago`;
  const months = Math.floor(days / 30);
  return `${months}mo ago`;
}
