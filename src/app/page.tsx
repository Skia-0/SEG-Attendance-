import type * as React from "react";
import Link from "next/link";
import { db } from "@/db";
import { hubs, coordinators } from "@/db/schema";
import { count } from "drizzle-orm";
import { Logo } from "@/components/Logo";
import { Reveal } from "@/components/ui";
import {
  ArrowRight,
  Building,
  Users,
  Nfc,
  Fingerprint,
  Clock,
  Shield,
  Check,
  Spark,
} from "@/components/icons";

export const dynamic = "force-dynamic";

async function liveCounts() {
  try {
    const [h] = await db.select({ n: count() }).from(hubs);
    const [c] = await db.select({ n: count() }).from(coordinators);
    return { hubs: h?.n ?? 0, coordinators: c?.n ?? 0 };
  } catch {
    return { hubs: 0, coordinators: 0 };
  }
}

const CITIES = ["Accra", "Kumasi", "Tamale", "Takoradi", "Cape Coast", "Sekondi", "Koforidua", "Sunyani", "Ho", "Bolgatanga"];

export default async function HomePage() {
  const counts = await liveCounts();

  return (
    <div className="relative min-h-screen overflow-hidden bg-paper text-ink">
      {/* ambient layer */}
      <div className="pointer-events-none absolute inset-0 -z-10">
        <div className="absolute inset-0 bg-grid" />
        <div className="absolute -right-40 -top-40 h-[520px] w-[520px] rounded-full glow-brand anim-pulse-glow opacity-70" />
        <div className="absolute left-[-10%] top-[40%] h-[360px] w-[360px] rounded-full bg-[radial-gradient(closest-side,rgba(20,107,63,0.12),transparent)] blur-2xl" />
        <div className="absolute inset-x-0 bottom-0 h-40 bg-gradient-to-t from-paper to-transparent" />
      </div>

      {/* ---------- top bar ---------- */}
      <header className="sticky top-0 z-40 border-b border-ink/5 bg-paper/80 backdrop-blur-md">
        <div className="mx-auto flex max-w-7xl items-center justify-between px-5 py-3.5 sm:px-8">
          <Link href="/" className="text-[26px] sm:text-[30px]" aria-label="SEG home">
            <Logo animated />
          </Link>
          <nav className="hidden items-center gap-7 text-sm font-medium text-ink/70 md:flex">
            <a href="#roles" className="link-underline hover:text-ink">Roles</a>
            <a href="#flow" className="link-underline hover:text-ink">How it works</a>
            <a href="#network" className="link-underline hover:text-ink">Network</a>
          </nav>
          <div className="flex items-center gap-2">
            <Link
              href="/auth?mode=login"
              className="hidden rounded-full px-4 py-2 text-sm font-semibold text-ink/80 transition-colors hover:text-ink sm:inline-block"
            >
              Sign in
            </Link>
            <Link
              href="/auth?mode=register"
              className="group inline-flex items-center gap-1.5 rounded-full bg-ink px-4 py-2 text-sm font-semibold text-paper transition-transform hover:-translate-y-0.5"
            >
              Create account
              <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-0.5" />
            </Link>
          </div>
        </div>
      </header>

      {/* ---------- hero ---------- */}
      <section className="mx-auto grid max-w-7xl items-center gap-12 px-5 pb-16 pt-12 sm:px-8 lg:grid-cols-[1.05fr_0.95fr] lg:pb-24 lg:pt-20">
        <div>
          <Reveal>
            <span className="inline-flex items-center gap-2 rounded-full border border-brand/30 bg-brand-100/60 px-3 py-1 text-xs font-semibold uppercase tracking-[0.14em] text-brand-700">
              <span className="relative flex h-2 w-2">
                <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-brand opacity-70" />
                <span className="relative inline-flex h-2 w-2 rounded-full bg-brand" />
              </span>
              Attendance system · Ghana
            </span>
          </Reveal>
          <Reveal delay={80}>
            <h1 className="mt-5 font-display text-[clamp(2.6rem,6.4vw,4.9rem)] font-extrabold leading-[0.95] tracking-[-0.02em] text-ink">
              Every learner,
              <br />
              <span className="text-brand">checked in.</span>{" "}
              <span className="text-ink/40">Every hub,</span>
              <br />
              accounted for.
            </h1>
          </Reveal>
          <Reveal delay={160}>
            <p className="mt-6 max-w-xl text-lg leading-relaxed text-ink/70">
              SEG Attendance is the sign-in layer for Social Enterprise Ghana — hubs register
              once, coordinators run sessions from their phones, and learners tap NFC or scan a
              fingerprint to mark presence. No paper. No guesswork.
            </p>
          </Reveal>
          <Reveal delay={240}>
            <div className="mt-8 flex flex-wrap items-center gap-3">
              <Link
                href="/auth?mode=register&role=hub"
                className="group inline-flex items-center gap-2 rounded-full bg-brand px-6 py-3.5 text-base font-bold text-[#1a0f02] shadow-[0_14px_30px_rgba(247,148,29,0.4)] transition-transform hover:-translate-y-0.5"
              >
                Register a hub
                <ArrowRight className="h-5 w-5 transition-transform group-hover:translate-x-1" />
              </Link>
              <Link
                href="/auth?mode=login&role=coordinator"
                className="inline-flex items-center gap-2 rounded-full border border-ink/15 bg-white px-6 py-3.5 text-base font-semibold text-ink transition-colors hover:border-ink/30"
              >
                <Users className="h-5 w-5 text-brand-700" />
                Coordinator sign in
              </Link>
            </div>
          </Reveal>
          <Reveal delay={320}>
            <dl className="mt-10 flex flex-wrap gap-x-10 gap-y-4">
              <Stat n={counts.hubs} label="hubs onboarded" />
              <Stat n={counts.coordinators} label="coordinators" />
              <Stat n="2" label="check-in methods" sub="NFC · fingerprint" />
            </dl>
          </Reveal>
        </div>

        {/* hero visual */}
        <Reveal delay={200} className="relative">
          <div className="relative mx-auto max-w-md">
            <div className="absolute -inset-6 -z-10 rounded-[2.4rem] glow-brand anim-pulse-glow opacity-80" />
            <div className="relative overflow-hidden rounded-[1.8rem] border border-white/10 bg-ink p-5 text-paper shadow-[0_40px_80px_-20px_rgba(18,11,5,0.5)] scroll-ink">
              <div className="pointer-events-none absolute inset-0 bg-grid-ink opacity-60" />
              <div className="relative">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2.5">
                    <span className="grid h-9 w-9 place-items-center rounded-xl bg-brand text-[#1a0f02]">
                      <Spark className="h-5 w-5" />
                    </span>
                    <div>
                      <p className="text-[0.7rem] uppercase tracking-[0.18em] text-white/50">Live session</p>
                      <p className="font-display text-lg font-bold leading-tight">SEG‑ACC‑0142</p>
                    </div>
                  </div>
                  <span className="inline-flex items-center gap-1.5 rounded-full bg-palm/25 px-2.5 py-1 text-[0.7rem] font-semibold text-palm-300">
                    <span className="h-1.5 w-1.5 rounded-full bg-palm-300 anim-pulse-glow" /> open
                  </span>
                </div>

                <div className="mt-5 space-y-2.5">
                  {[
                    { i: "AA", n: "Ama Asante", m: "NFC", t: "08:54" },
                    { i: "KO", n: "Kofi Owusu", m: "Fingerprint", t: "08:56" },
                    { i: "ED", n: "Efua Dentaa", m: "NFC", t: "08:57" },
                    { i: "YM", n: "Yaw Mensah", m: "Fingerprint", t: "09:01" },
                  ].map((r, idx) => (
                    <div
                      key={r.i}
                      className="flex items-center gap-3 rounded-2xl border border-white/8 bg-white/[0.04] px-3 py-2.5 anim-pop"
                      style={{ animationDelay: `${idx * 120}ms` }}
                    >
                      <span className="grid h-9 w-9 place-items-center rounded-full bg-brand/20 font-display text-sm font-bold text-brand-300">
                        {r.i}
                      </span>
                      <div className="min-w-0 flex-1">
                        <p className="truncate text-sm font-semibold">{r.n}</p>
                        <p className="text-[0.7rem] text-white/45">checked in</p>
                      </div>
                      <span
                        className={`inline-flex items-center gap-1 rounded-full px-2 py-1 text-[0.68rem] font-semibold ${
                          r.m === "NFC" ? "bg-brand/15 text-brand-300" : "bg-palm/20 text-palm-300"
                        }`}
                      >
                        {r.m === "NFC" ? <Nfc className="h-3.5 w-3.5" /> : <Fingerprint className="h-3.5 w-3.5" />}
                        {r.m}
                      </span>
                      <span className="font-mono text-xs text-white/50">{r.t}</span>
                    </div>
                  ))}
                </div>

                <div className="mt-5">
                  <div className="flex items-center justify-between text-xs text-white/55">
                    <span>Present</span>
                    <span className="font-mono text-white/80">18 / 24</span>
                  </div>
                  <div className="mt-1.5 h-2 overflow-hidden rounded-full bg-white/10">
                    <div className="h-full rounded-full bg-gradient-to-r from-brand-600 to-brand-300" style={{ width: "75%" }} />
                  </div>
                </div>
              </div>
            </div>

            {/* floating chips */}
            <div className="absolute -left-6 top-10 anim-floaty rounded-2xl border border-ink/10 bg-white px-3.5 py-2.5 shadow-xl" style={{ "--rot": "-6deg" } as React.CSSProperties}>
              <div className="flex items-center gap-2">
                <span className="grid h-7 w-7 place-items-center rounded-lg bg-palm/15 text-palm"><Check className="h-4 w-4" /></span>
                <div>
                  <p className="text-[0.7rem] font-semibold leading-tight text-ink">NFC tap verified</p>
                  <p className="text-[0.65rem] text-ink/50">UID · 04:A2:…:1F</p>
                </div>
              </div>
            </div>
            <div className="absolute -right-5 bottom-12 anim-floaty-slow rounded-2xl border border-ink/10 bg-white px-3.5 py-2.5 shadow-xl" style={{ "--rot": "5deg" } as React.CSSProperties}>
              <div className="flex items-center gap-2">
                <span className="grid h-7 w-7 place-items-center rounded-lg bg-brand/15 text-brand-700"><Clock className="h-4 w-4" /></span>
                <div>
                  <p className="text-[0.7rem] font-semibold leading-tight text-ink">Session opened</p>
                  <p className="text-[0.65rem] text-ink/50">by coordinator · 08:50</p>
                </div>
              </div>
            </div>
          </div>
        </Reveal>
      </section>

      {/* ---------- city marquee ---------- */}
      <div className="relative border-y border-ink/8 bg-ink py-4 text-paper">
        <div className="flex overflow-hidden [mask-image:linear-gradient(to_right,transparent,#000_8%,#000_92%,transparent)]">
          <div className="anim-marquee flex shrink-0 items-center gap-10 pr-10">
            {[...CITIES, ...CITIES].map((c, i) => (
              <span key={i} className="flex items-center gap-10 font-display text-lg font-semibold tracking-tight text-white/70">
                {c}
                <span className="h-1.5 w-1.5 rounded-full bg-brand" />
              </span>
            ))}
          </div>
        </div>
      </div>

      {/* ---------- roles ---------- */}
      <section id="roles" className="mx-auto max-w-7xl px-5 py-20 sm:px-8 lg:py-28">
        <Reveal className="max-w-2xl">
          <p className="text-sm font-semibold uppercase tracking-[0.2em] text-brand-700">Two roles, one system</p>
          <h2 className="mt-3 font-display text-[clamp(2rem,4.4vw,3.2rem)] font-extrabold leading-[1.02] tracking-tight">
            Register as the place, or as the person running it.
          </h2>
        </Reveal>

        <div className="mt-12 grid gap-6 lg:grid-cols-[1.1fr_0.9fr]">
          <Reveal>
            <RoleCard
              index="01"
              tone="ink"
              icon={<Building className="h-6 w-6" />}
              title="Hub"
              tagline="The training centre"
              body="A hub is your physical site — Accra, Kumasi, anywhere. Register it once with an admin email, then invite coordinators under it and watch attendance roll in."
              bullets={["Admin email + password login", "See every coordinator on your roster", "Wi‑Fi SSID stored for on‑site check-ins", "Owns its cohorts & sessions"]}
              cta={{ label: "Register a hub", href: "/auth?mode=register&role=hub" }}
            />
          </Reveal>
          <Reveal delay={120}>
            <RoleCard
              index="02"
              tone="brand"
              icon={<Users className="h-6 w-6" />}
              title="Coordinator"
              tagline="The person on the floor"
              body="Coordinators sign in with their phone number, pick their hub, and run sessions from the mobile app — opening check-in, scanning NFC and fingerprints, closing out."
              bullets={["Phone + password login", "Attached to exactly one hub", "Runs sessions from the app", "Records NFC & fingerprint taps"]}
              cta={{ label: "Coordinator sign in", href: "/auth?mode=login&role=coordinator" }}
            />
          </Reveal>
        </div>
      </section>

      {/* ---------- flow ---------- */}
      <section id="flow" className="relative bg-paper-2/60 py-20 lg:py-28">
        <div className="pointer-events-none absolute inset-0 bg-dots opacity-50" />
        <div className="relative mx-auto max-w-7xl px-5 sm:px-8">
          <Reveal className="max-w-2xl">
            <p className="text-sm font-semibold uppercase tracking-[0.2em] text-brand-700">A session, end to end</p>
            <h2 className="mt-3 font-display text-[clamp(2rem,4.4vw,3.2rem)] font-extrabold leading-[1.02] tracking-tight">
              From open bell to certificate, in four moves.
            </h2>
          </Reveal>
          <ol className="relative mt-14 grid gap-6 md:grid-cols-2 lg:grid-cols-4">
            <span className="pointer-events-none absolute left-0 right-0 top-7 hidden h-px bg-gradient-to-r from-brand/0 via-brand/40 to-brand/0 lg:block" />
            {[
              { k: "Create", t: "Set up the cohort", d: "Name it, attach it to a hub, learners get a SEG‑ id.", icon: <Users className="h-5 w-5" /> },
              { k: "Open", t: "Start the session", d: "Coordinator opens check-in from the app with one tap.", icon: <Clock className="h-5 w-5" /> },
              { k: "Check in", t: "NFC or fingerprint", d: "Learners tap a tag or scan a finger — presence logged instantly.", icon: <Nfc className="h-5 w-5" /> },
              { k: "Close", t: "End & certify", d: "Close the session; attendance totals feed certification.", icon: <Shield className="h-5 w-5" /> },
            ].map((s, i) => (
              <Reveal as="li" key={s.k} delay={i * 90} className="relative">
                <div className="group h-full rounded-3xl border border-ink/8 bg-white p-6 transition-transform duration-300 hover:-translate-y-1.5 hover:shadow-[0_24px_50px_-20px_rgba(18,11,5,0.25)]">
                  <div className="flex items-center justify-between">
                    <span className="grid h-12 w-12 place-items-center rounded-2xl bg-ink text-brand transition-colors group-hover:bg-brand group-hover:text-[#1a0f02]">
                      {s.icon}
                    </span>
                    <span className="font-display text-3xl font-extrabold text-ink/10">0{i + 1}</span>
                  </div>
                  <p className="mt-5 text-xs font-semibold uppercase tracking-[0.18em] text-brand-700">{s.k}</p>
                  <h3 className="mt-1 font-display text-xl font-bold">{s.t}</h3>
                  <p className="mt-2 text-sm leading-relaxed text-ink/60">{s.d}</p>
                </div>
              </Reveal>
            ))}
          </ol>
        </div>
      </section>

      {/* ---------- network band ---------- */}
      <section id="network" className="relative overflow-hidden bg-ink py-20 text-paper lg:py-24">
        <div className="pointer-events-none absolute inset-0 bg-grid-ink opacity-70" />
        <div className="pointer-events-none absolute left-1/2 top-0 h-72 w-72 -translate-x-1/2 rounded-full glow-brand anim-pulse-glow opacity-60" />
        <div className="relative mx-auto grid max-w-7xl items-center gap-12 px-5 sm:px-8 lg:grid-cols-2">
          <Reveal>
            <p className="text-sm font-semibold uppercase tracking-[0.2em] text-brand-300">The network, live</p>
            <h2 className="mt-3 font-display text-[clamp(2rem,4.4vw,3.4rem)] font-extrabold leading-[1.02] tracking-tight">
              Numbers that move the moment a hub signs in.
            </h2>
            <p className="mt-5 max-w-md text-white/65">
              These aren't mocked figures — they're read straight from the SEG database. Register a
              hub and the counter ticks up in real time.
            </p>
            <Link
              href="/auth?mode=register"
              className="group mt-7 inline-flex items-center gap-2 rounded-full bg-brand px-6 py-3.5 font-bold text-[#1a0f02] transition-transform hover:-translate-y-0.5"
            >
              Add your hub to the map
              <ArrowRight className="h-5 w-5 transition-transform group-hover:translate-x-1" />
            </Link>
          </Reveal>
          <Reveal delay={120}>
            <div className="grid grid-cols-2 gap-4">
              <BigStat n={counts.hubs} label="Hubs registered" empty="Be the first" />
              <BigStat n={counts.coordinators} label="Coordinators active" empty="None yet" />
              <BigStat n="100%" label="On‑device check‑in" />
              <BigStat n="2" label="Biometric methods" sub="NFC · fingerprint" />
            </div>
          </Reveal>
        </div>
      </section>

      {/* ---------- final cta ---------- */}
      <section className="mx-auto max-w-7xl px-5 py-20 sm:px-8 lg:py-28">
        <Reveal>
          <div className="relative overflow-hidden rounded-[2.2rem] border border-brand/20 bg-gradient-to-br from-brand-100 via-paper to-paper p-8 sm:p-14">
            <div className="pointer-events-none absolute -right-16 -top-16 h-72 w-72 rounded-full glow-brand anim-pulse-glow opacity-70" />
            <div className="relative grid items-center gap-8 lg:grid-cols-[1.4fr_1fr]">
              <div>
                <h2 className="font-display text-[clamp(1.9rem,4vw,3rem)] font-extrabold leading-[1.03] tracking-tight text-ink">
                  Bring attendance online for your hub today.
                </h2>
                <p className="mt-4 max-w-lg text-ink/65">
                  Create a hub account, or sign in as a coordinator. Passwords stay yours — toggle
                  the eye to see what you're typing, any time.
                </p>
              </div>
              <div className="flex flex-col gap-3 sm:flex-row lg:flex-col">
                <Link href="/auth?mode=register&role=hub" className="inline-flex items-center justify-center gap-2 rounded-full bg-ink px-6 py-3.5 font-bold text-paper transition-transform hover:-translate-y-0.5">
                  Register hub <ArrowRight className="h-5 w-5" />
                </Link>
                <Link href="/auth?mode=register&role=coordinator" className="inline-flex items-center justify-center gap-2 rounded-full border border-ink/15 bg-white px-6 py-3.5 font-semibold text-ink transition-colors hover:border-ink/30">
                  Register coordinator
                </Link>
              </div>
            </div>
          </div>
        </Reveal>
      </section>

      {/* ---------- footer ---------- */}
      <footer className="bg-ink text-paper">
        <div className="mx-auto grid max-w-7xl gap-10 px-5 py-14 sm:px-8 md:grid-cols-[1.4fr_1fr_1fr]">
          <div>
            <div className="text-[30px]"><Logo tone="light" animated /></div>
            <p className="mt-4 max-w-xs text-sm text-white/55">
              The attendance backbone for Social Enterprise Ghana — hubs, coordinators, cohorts and
              biometric check-ins in one place.
            </p>
          </div>
          <FooterCol title="Access" links={[["Sign in", "/auth?mode=login"], ["Register a hub", "/auth?mode=register&role=hub"], ["Register coordinator", "/auth?mode=register&role=coordinator"]]} />
          <FooterCol title="System" links={[["How it works", "#flow"], ["Roles", "#roles"], ["Network", "#network"]]} />
        </div>
        <div className="border-t border-white/10">
          <div className="mx-auto flex max-w-7xl flex-col items-start justify-between gap-2 px-5 py-5 text-xs text-white/45 sm:flex-row sm:items-center sm:px-8">
            <p>© {new Date().getFullYear()} Social Enterprise Ghana · SEG Attendance</p>
            <p className="font-mono">built with Next.js · PostgreSQL · Drizzle</p>
          </div>
        </div>
      </footer>
    </div>
  );
}

function Stat({ n, label, sub }: { n: number | string; label: string; sub?: string }) {
  return (
    <div>
      <dt className="font-display text-3xl font-extrabold text-ink tabular-nums">{n}</dt>
      <dd className="mt-0.5 text-sm text-ink/55">{label}</dd>
      {sub && <dd className="text-xs text-ink/40">{sub}</dd>}
    </div>
  );
}

function BigStat({ n, label, sub, empty }: { n: number | string; label: string; sub?: string; empty?: string }) {
  const isZero = typeof n === "number" && n === 0;
  return (
    <div className="rounded-3xl border border-white/10 bg-white/[0.04] p-6">
      <p className="font-display text-4xl font-extrabold tabular-nums text-brand-300 sm:text-5xl">
        {isZero && empty ? <span className="text-2xl text-white/40">{empty}</span> : n}
      </p>
      <p className="mt-2 text-sm text-white/60">{label}</p>
      {sub && <p className="text-xs text-white/40">{sub}</p>}
    </div>
  );
}

function RoleCard({
  index,
  tone,
  icon,
  title,
  tagline,
  body,
  bullets,
  cta,
}: {
  index: string;
  tone: "ink" | "brand";
  icon: React.ReactNode;
  title: string;
  tagline: string;
  body: string;
  bullets: string[];
  cta: { label: string; href: string };
}) {
  const ink = tone === "ink";
  return (
    <div
      className={`group relative flex h-full flex-col overflow-hidden rounded-[1.8rem] p-8 transition-transform duration-300 hover:-translate-y-1.5 ${
        ink ? "bg-ink text-paper" : "bg-brand text-[#1a0f02]"
      }`}
    >
      <div className={`pointer-events-none absolute inset-0 ${ink ? "bg-grid-ink opacity-60" : "bg-[radial-gradient(circle_at_80%_0%,rgba(255,255,255,0.35),transparent_55%)]"}`} />
      <div className="relative flex items-start justify-between">
        <span className={`grid h-14 w-14 place-items-center rounded-2xl ${ink ? "bg-brand text-[#1a0f02]" : "bg-[#1a0f02] text-brand"}`}>{icon}</span>
        <span className={`font-display text-5xl font-extrabold ${ink ? "text-white/10" : "text-[#1a0f02]/15"}`}>{index}</span>
      </div>
      <div className="relative mt-6">
        <p className={`text-xs font-semibold uppercase tracking-[0.2em] ${ink ? "text-brand-300" : "text-[#1a0f02]/70"}`}>{tagline}</p>
        <h3 className="mt-1 font-display text-3xl font-extrabold tracking-tight">{title}</h3>
        <p className={`mt-3 text-[0.95rem] leading-relaxed ${ink ? "text-white/70" : "text-[#1a0f02]/80"}`}>{body}</p>
      </div>
      <ul className="relative mt-6 space-y-2.5">
        {bullets.map((b) => (
          <li key={b} className="flex items-start gap-2.5 text-sm">
            <span className={`mt-0.5 grid h-5 w-5 shrink-0 place-items-center rounded-full ${ink ? "bg-white/10 text-brand-300" : "bg-[#1a0f02]/15 text-[#1a0f02]"}`}>
              <Check className="h-3.5 w-3.5" />
            </span>
            <span className={ink ? "text-white/80" : "text-[#1a0f02]/85"}>{b}</span>
          </li>
        ))}
      </ul>
      <Link
        href={cta.href}
        className={`relative mt-8 inline-flex items-center justify-between gap-2 rounded-full px-5 py-3 text-sm font-bold transition-colors ${
          ink ? "bg-white text-ink hover:bg-brand-100" : "bg-[#1a0f02] text-paper hover:bg-[#2a1d10]"
        }`}
      >
        {cta.label}
        <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-1" />
      </Link>
    </div>
  );
}

function FooterCol({ title, links }: { title: string; links: [string, string][] }) {
  return (
    <div>
      <p className="text-xs font-semibold uppercase tracking-[0.2em] text-white/40">{title}</p>
      <ul className="mt-4 space-y-2.5 text-sm">
        {links.map(([label, href]) => (
          <li key={label}>
            <Link href={href} className="text-white/70 transition-colors hover:text-brand-300">{label}</Link>
          </li>
        ))}
      </ul>
    </div>
  );
}
