"use client";
import type * as React from "react";
import { useEffect, useMemo, useRef, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Logo, Bulb } from "@/components/Logo";
import { Field, PasswordField, Segmented, Spinner, useToast } from "@/components/ui";
import {
  Building,
  Users,
  Mail,
  MapPin,
  Wifi,
  User,
  Phone,
  ArrowRight,
  Check,
  Chevron,
  Lock,
} from "@/components/icons";
import { normalizePhone } from "@/lib/auth";
import { saveSession, type SessionUser } from "@/lib/session";

type Mode = "login" | "register";
type Role = "hub" | "coordinator";
type HubOption = { id: string; name: string; location: string };

const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export default function AuthShell({
  initialMode,
  initialRole,
}: {
  initialMode: Mode;
  initialRole: Role;
}) {
  const router = useRouter();
  const toast = useToast();
  const [mode, setMode] = useState<Mode>(initialMode);
  const [role, setRole] = useState<Role>(initialRole);
  const [loading, setLoading] = useState(false);
  const [errs, setErrs] = useState<Record<string, string>>({});
  const [pwMirror, setPwMirror] = useState("");
  const [apiOk, setApiOk] = useState<boolean | null>(null);
  const [hubs, setHubs] = useState<HubOption[]>([]);
  const [hubsLoading, setHubsLoading] = useState(false);

  // Uncontrolled inputs → native typing always works; we read on submit.
  const hubNameRef = useRef<HTMLInputElement>(null);
  const locationRef = useRef<HTMLInputElement>(null);
  const wifiRef = useRef<HTMLInputElement>(null);
  const adminEmailRef = useRef<HTMLInputElement>(null);
  const fullNameRef = useRef<HTMLInputElement>(null);
  const phoneRef = useRef<HTMLInputElement>(null);
  const hubIdRef = useRef<HTMLSelectElement>(null);
  const passwordRef = useRef<HTMLInputElement>(null);
  const confirmRef = useRef<HTMLInputElement>(null);

  const isRegister = mode === "register";
  const isHub = role === "hub";

  // connection pre-check so a dead server is obvious, not silent
  useEffect(() => {
    const ctrl = new AbortController();
    fetch("/api/health", { signal: ctrl.signal, cache: "no-store" })
      .then((r) => setApiOk(r.ok))
      .catch(() => setApiOk(false));
    return () => ctrl.abort();
  }, []);

  // load hubs for the coordinator hub-picker
  useEffect(() => {
    if (role !== "coordinator") return;
    let alive = true;
    setHubsLoading(true);
    fetch("/api/auth/hubs", { cache: "no-store" })
      .then((r) => r.json())
      .then((d) => alive && setHubs(Array.isArray(d?.hubs) ? d.hubs : []))
      .catch(() => alive && setHubs([]))
      .finally(() => alive && setHubsLoading(false));
    return () => {
      alive = false;
    };
  }, [role]);

  // keep URL shareable WITHOUT triggering a Next soft-nav (no remount risk)
  useEffect(() => {
    const url = new URL(window.location.href);
    url.searchParams.set("mode", mode);
    url.searchParams.set("role", role);
    if (url.toString() !== window.location.href) {
      window.history.replaceState(null, "", url.pathname + url.search);
    }
  }, [mode, role]);

  const context = useMemo(() => {
    if (isHub && isRegister)
      return {
        head: "Put your training centre on the map.",
        sub: "You'll set an admin login and own every coordinator registered under this hub.",
      };
    if (isHub && !isRegister)
      return { head: "Welcome back, hub admin.", sub: "Sign in with the admin email you registered." };
    if (!isHub && isRegister)
      return {
        head: "Join a hub as a coordinator.",
        sub: "Pick the hub you run sessions for — you can belong to one at a time.",
      };
    return { head: "Sign in to run sessions.", sub: "Use the phone number you registered with." };
  }, [isHub, isRegister]);

  const clearErr = (k: string) =>
    setErrs((prev) => {
      if (!(k in prev)) return prev;
      const n = { ...prev };
      delete n[k];
      return n;
    });
  const bind = (k: string) => () => {
    clearErr(k);
    clearErr("form");
  };

  function changeMode(m: Mode) {
    setMode(m);
    setErrs({});
  }
  function changeRole(r: Role) {
    setRole(r);
    setErrs({});
  }

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setErrs({});

    const get = (r: React.RefObject<HTMLInputElement | HTMLSelectElement | null>) => r.current?.value ?? "";
    const trim = (r: React.RefObject<HTMLInputElement | HTMLSelectElement | null>) => get(r).trim();

    const next: Record<string, string> = {};
    if (isHub && isRegister) {
      if (!trim(hubNameRef)) next.hubName = "Give your hub a name.";
      if (!trim(locationRef)) next.location = "Add a city or neighbourhood.";
      const em = trim(adminEmailRef);
      if (!em) next.adminEmail = "Admin email is required.";
      else if (!EMAIL.test(em)) next.adminEmail = "That email doesn't look right.";
    }
    if (isHub && !isRegister) {
      if (!trim(adminEmailRef)) next.adminEmail = "Enter your admin email.";
    }
    if (!isHub && isRegister) {
      if (!trim(fullNameRef)) next.fullName = "Your name, please.";
      if (!trim(phoneRef)) next.phone = "Phone number is required.";
      if (!hubIdRef.current?.value) next.hubId = "Pick the hub you work with.";
    }
    if (!isHub && !isRegister) {
      if (!trim(phoneRef)) next.phone = "Enter your phone number.";
    }

    const pw = passwordRef.current?.value ?? "";
    if (!pw) next.password = "Password is required.";
    else if (isRegister && pw.length < 6) next.password = "Use at least 6 characters.";
    if (isRegister) {
      const cf = confirmRef.current?.value ?? "";
      if (!cf) next.confirm = "Confirm your password.";
      else if (cf !== pw) next.confirm = "Passwords don't match — check both fields.";
    }

    if (Object.keys(next).length) {
      setErrs(next);
      toast({ type: "error", title: "A couple of fields need attention", desc: "The highlighted fields below need fixing." });
      const order = ["hubName", "location", "adminEmail", "fullName", "phone", "hubId", "password", "confirm"] as const;
      const first = order.find((k) => next[k]);
      const refMap: Record<string, React.RefObject<HTMLInputElement | HTMLSelectElement | null>> = {
        hubName: hubNameRef,
        location: locationRef,
        adminEmail: adminEmailRef,
        fullName: fullNameRef,
        phone: phoneRef,
        hubId: hubIdRef,
        password: passwordRef,
        confirm: confirmRef,
      };
      if (first) refMap[first].current?.focus();
      return;
    }

    const url =
      role === "hub"
        ? isRegister
          ? "/api/auth/hub/register"
          : "/api/auth/hub/login"
        : isRegister
        ? "/api/auth/coordinator/register"
        : "/api/auth/coordinator/login";

    let payload: Record<string, string> = {};
    if (isHub && isRegister)
      payload = {
        name: trim(hubNameRef),
        location: trim(locationRef),
        wifi_ssid: trim(wifiRef),
        admin_email: trim(adminEmailRef).toLowerCase(),
        password: pw,
      };
    else if (isHub && !isRegister)
      payload = { admin_email: trim(adminEmailRef).toLowerCase(), password: pw };
    else if (!isHub && isRegister)
      payload = {
        full_name: trim(fullNameRef),
        phone: normalizePhone(get(phoneRef)),
        password: pw,
        hub_id: hubIdRef.current?.value ?? "",
      };
    else payload = { phone: normalizePhone(get(phoneRef)), password: pw };

    setLoading(true);
    try {
      const res = await fetch(url, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify(payload),
      });
      let data: any = {};
      const text = await res.text();
      try {
        data = text ? JSON.parse(text) : {};
      } catch {
        data = {};
      }
      if (!res.ok) {
        const msg =
          (typeof data?.error === "string" && data.error) ||
          `Server replied ${res.status}. Please try again.`;
        // eslint-disable-next-line no-console
        console.error("[SEG] auth failed", { status: res.status, body: data, payload: { ...payload, password: "•••" } });
        setErrs({ form: msg });
        toast({ type: "error", title: isRegister ? "Registration didn't go through" : "Sign-in failed", desc: msg });
        return;
      }
      const token: string = data.token;
      const r = data.role as Role;
      const user: SessionUser =
        r === "hub"
          ? { role: "hub", id: data.hub.id, name: data.hub.name, location: data.hub.location, admin_email: data.hub.admin_email }
          : {
              role: "coordinator",
              id: data.coordinator.id,
              full_name: data.coordinator.full_name,
              phone: data.coordinator.phone,
              hub_id: data.coordinator.hub_id,
              hub_name: data.coordinator.hub_name,
            };
      saveSession(token, r, user);
      const displayName = user.role === "hub" ? user.name : user.full_name;
      toast({
        type: "success",
        title: isRegister ? (r === "hub" ? "Hub created — welcome" : "Coordinator registered") : "Signed in",
        desc: isRegister ? "Opening your dashboard." : `Welcome back, ${displayName.split(" ")[0]}.`,
      });
      router.push("/dashboard");
    } catch (err) {
      // eslint-disable-next-line no-console
      console.error("[SEG] network error", err);
      setErrs({ form: "Couldn't reach the SEG server. Check your connection and try again." });
      toast({ type: "error", title: "Network error", desc: "No response from the server." });
    } finally {
      setLoading(false);
    }
  }

  const formBanner = errs.form;

  return (
    <div className="relative min-h-screen bg-paper text-ink">
      <div className="mx-auto grid min-h-screen lg:grid-cols-[0.92fr_1.08fr]">
        {/* ---------- left ink panel ---------- */}
        <aside className="relative hidden overflow-hidden bg-ink p-10 text-paper lg:flex lg:flex-col lg:p-14">
          <div className="pointer-events-none absolute inset-0 bg-grid-ink opacity-70" />
          <div className="pointer-events-none absolute -right-24 top-10 h-80 w-80 rounded-full glow-brand anim-pulse-glow opacity-70" />
          <div className="pointer-events-none absolute -left-10 bottom-0 h-72 w-72 rounded-full bg-[radial-gradient(closest-side,rgba(20,107,63,0.3),transparent)] blur-2xl" />
          <div className="relative">
            <Link href="/" className="text-[34px]"><Logo tone="light" animated /></Link>
          </div>

          <div className="relative mt-auto">
            <div className="anim-floaty-slow mb-8 inline-block">
              <Bulb animated className="h-28 w-auto drop-shadow-[0_10px_30px_rgba(247,148,29,0.45)]" />
            </div>
            <h2 key={context.head} className="anim-pop max-w-md font-display text-[2.1rem] font-extrabold leading-[1.05] tracking-tight">
              {context.head}
            </h2>
            <p key={context.sub} className="anim-pop mt-3 max-w-md text-white/65">{context.sub}</p>

            <ul className="mt-8 space-y-3 text-sm">
              {[
                "Tap the eye to reveal your password while typing",
                isHub ? "One admin email per hub — it's your username" : "Your phone number is your username",
                "Passwords are salted & hashed; we never store them plain",
              ].map((t) => (
                <li key={t} className="flex items-center gap-2.5 text-white/75">
                  <span className="grid h-5 w-5 shrink-0 place-items-center rounded-full bg-brand/20 text-brand-300"><Check className="h-3.5 w-3.5" /></span>
                  {t}
                </li>
              ))}
            </ul>
          </div>

          <p className="relative mt-10 text-xs text-white/40">Social Enterprise Ghana · SEG Attendance</p>
        </aside>

        {/* ---------- right form ---------- */}
        <main className="relative flex items-center justify-center px-5 py-10 sm:px-8">
          <div className="pointer-events-none absolute inset-0 -z-10 bg-dots opacity-40" />
          <div className="absolute left-5 right-5 top-5 flex items-center justify-between lg:hidden">
            <Link href="/" className="text-[26px]"><Logo animated /></Link>
            <Link href="/" className="text-sm font-semibold text-ink/60">Home</Link>
          </div>

          <div className="w-full max-w-md pt-16 lg:pt-0">
            <div className="mb-7 hidden lg:block">
              <p className="text-xs font-semibold uppercase tracking-[0.2em] text-brand-700">SEG Attendance</p>
              <h1 className="mt-2 font-display text-3xl font-extrabold tracking-tight">
                {isRegister ? "Create your account" : "Sign in to continue"}
              </h1>
              <p className="mt-1.5 text-sm text-ink/55">
                {isRegister
                  ? isHub
                    ? "Registering a new hub — fill all four fields, then create."
                    : "Registering a coordinator — pick your hub from the list."
                  : isHub
                  ? "Signing in as a hub admin — use your admin email."
                  : "Signing in as a coordinator — use your phone number."}
              </p>
            </div>

            <Segmented<Mode>
              value={mode}
              onChange={changeMode}
              options={[
                { value: "login", label: "Sign in", icon: <Lock className="h-4 w-4" /> },
                { value: "register", label: "Register", icon: <Spark className="h-4 w-4" /> },
              ]}
            />
            <div className="mt-3">
              <Segmented<Role>
                value={role}
                onChange={changeRole}
                options={[
                  { value: "hub", label: "Hub", icon: <Building className="h-4 w-4" /> },
                  { value: "coordinator", label: "Coordinator", icon: <Users className="h-4 w-4" /> },
                ]}
              />
            </div>

            {/* connection banner */}
            {apiOk === false && (
              <div role="alert" className="mt-4 flex items-start gap-2.5 rounded-xl border border-brand/40 bg-brand-100/70 px-3.5 py-2.5 text-sm text-brand-700 anim-pop">
                <span className="font-display text-base font-extrabold leading-none">i</span>
                <span>We can't reach the SEG server right now. You can still fill the form; submit will retry.</span>
              </div>
            )}

            <form onSubmit={submit} className="mt-6 space-y-4" noValidate>
              {isHub && isRegister && (
                <>
                  <Field label="Hub name" icon={<Building className="h-3.5 w-3.5" />} htmlFor="hubName" error={errs.hubName}>
                    <input
                      ref={hubNameRef}
                      id="hubName"
                      name="name"
                      className="field"
                      placeholder="e.g. SEG Accra Central"
                      autoComplete="organization"
                      aria-invalid={!!errs.hubName}
                      onChange={bind("hubName")}
                    />
                  </Field>
                  <Field label="Location" icon={<MapPin className="h-3.5 w-3.5" />} htmlFor="location" error={errs.location}>
                    <input
                      ref={locationRef}
                      id="location"
                      name="location"
                      className="field"
                      placeholder="City / neighbourhood"
                      autoComplete="address-level2"
                      aria-invalid={!!errs.location}
                      onChange={bind("location")}
                    />
                  </Field>
                  <Field label="Wi‑Fi SSID (optional)" icon={<Wifi className="h-3.5 w-3.5" />} htmlFor="wifi" hint="Stored so on‑site devices know the network.">
                    <input
                      ref={wifiRef}
                      id="wifi"
                      name="wifi_ssid"
                      className="field"
                      placeholder="SEG‑HUB‑5G"
                      onChange={bind("wifi")}
                    />
                  </Field>
                  <Field label="Admin email" icon={<Mail className="h-3.5 w-3.5" />} htmlFor="email" error={errs.adminEmail}>
                    <input
                      ref={adminEmailRef}
                      id="email"
                      name="admin_email"
                      type="email"
                      className="field"
                      placeholder="admin@yourhub.org"
                      autoComplete="email"
                      aria-invalid={!!errs.adminEmail}
                      onChange={bind("adminEmail")}
                    />
                  </Field>
                </>
              )}
              {isHub && !isRegister && (
                <Field label="Admin email" icon={<Mail className="h-3.5 w-3.5" />} htmlFor="email" error={errs.adminEmail}>
                  <input
                    ref={adminEmailRef}
                    id="email"
                    name="admin_email"
                    type="email"
                    className="field"
                    placeholder="admin@yourhub.org"
                    autoComplete="email"
                    aria-invalid={!!errs.adminEmail}
                    onChange={bind("adminEmail")}
                  />
                </Field>
              )}

              {!isHub && isRegister && (
                <>
                  <Field label="Full name" icon={<User className="h-3.5 w-3.5" />} htmlFor="fullName" error={errs.fullName}>
                    <input
                      ref={fullNameRef}
                      id="fullName"
                      name="full_name"
                      className="field"
                      placeholder="e.g. Ama Asante"
                      autoComplete="name"
                      aria-invalid={!!errs.fullName}
                      onChange={bind("fullName")}
                    />
                  </Field>
                  <Field label="Phone number" icon={<Phone className="h-3.5 w-3.5" />} htmlFor="phone" error={errs.phone} hint="This is your username — include country code.">
                    <input
                      ref={phoneRef}
                      id="phone"
                      name="phone"
                      type="tel"
                      className="field"
                      placeholder="+233 24 000 0000"
                      autoComplete="tel"
                      aria-invalid={!!errs.phone}
                      onChange={bind("phone")}
                    />
                  </Field>
                  <Field label="Hub" icon={<Building className="h-3.5 w-3.5" />} htmlFor="hubId" error={errs.hubId} hint={hubs.length === 0 && !hubsLoading ? "No hubs exist yet — register one first." : undefined}>
                    <div className="relative">
                      <select
                        ref={hubIdRef}
                        id="hubId"
                        name="hub_id"
                        className="field appearance-none pr-10"
                        aria-invalid={!!errs.hubId}
                        onChange={bind("hubId")}
                      >
                        <option value="">{hubsLoading ? "Loading hubs…" : "Select your hub"}</option>
                        {hubs.map((h) => (
                          <option key={h.id} value={h.id}>{h.name} — {h.location}</option>
                        ))}
                      </select>
                      <Chevron className="pointer-events-none absolute right-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-ink/40" />
                    </div>
                    {hubs.length === 0 && !hubsLoading && (
                      <button
                        type="button"
                        onClick={() => { changeRole("hub"); changeMode("register"); }}
                        className="mt-2 inline-flex items-center gap-1 text-xs font-semibold text-brand-700 link-underline"
                      >
                        Register the first hub <ArrowRight className="h-3.5 w-3.5" />
                      </button>
                    )}
                  </Field>
                </>
              )}
              {!isHub && !isRegister && (
                <Field label="Phone number" icon={<Phone className="h-3.5 w-3.5" />} htmlFor="phone" error={errs.phone}>
                  <input
                    ref={phoneRef}
                    id="phone"
                    name="phone"
                    type="tel"
                    className="field"
                    placeholder="+233 24 000 0000"
                    autoComplete="tel"
                    aria-invalid={!!errs.phone}
                    onChange={bind("phone")}
                  />
                </Field>
              )}

              {/* password + confirm reset together when the role changes */}
              <div key={`pw-${role}`} className="space-y-4">
                <Field label="Password" icon={<Lock className="h-3.5 w-3.5" />} htmlFor="password" error={errs.password}>
                  <PasswordField
                    id="password"
                    name="password"
                    inputRef={passwordRef}
                    onMirror={(v) => {
                      setPwMirror(v);
                      clearErr("password");
                      clearErr("form");
                    }}
                    showStrength={isRegister}
                    strengthValue={pwMirror}
                    autoComplete={isRegister ? "new-password" : "current-password"}
                    placeholder={isRegister ? "Create a password (6+ chars)" : "Your password"}
                  />
                </Field>

                {isRegister && (
                  <Field label="Confirm password" icon={<Lock className="h-3.5 w-3.5" />} htmlFor="confirm" error={errs.confirm}>
                    <PasswordField
                      id="confirm"
                      name="confirm"
                      inputRef={confirmRef}
                      onMirror={() => {
                        clearErr("confirm");
                        clearErr("form");
                      }}
                      autoComplete="new-password"
                      placeholder="Re-type your password"
                    />
                  </Field>
                )}
              </div>

              {/* form-level / server error banner (persistent until fixed) */}
              {formBanner && (
                <div role="alert" className="flex items-start gap-2.5 rounded-xl border border-ember/30 bg-ember/8 px-3.5 py-3 text-sm text-ember anim-pop">
                  <span className="font-display text-base font-extrabold leading-none">!</span>
                  <span>{formBanner}</span>
                </div>
              )}

              <button
                type="submit"
                disabled={loading}
                aria-busy={loading}
                className="group flex w-full items-center justify-center gap-2 rounded-2xl bg-brand px-5 py-3.5 text-base font-bold text-[#1a0f02] shadow-[0_14px_30px_rgba(247,148,29,0.35)] transition-all hover:-translate-y-0.5 hover:shadow-[0_18px_36px_rgba(247,148,29,0.45)] disabled:translate-y-0 disabled:opacity-70"
              >
                {loading ? (
                  <>
                    <Spinner className="h-5 w-5" />
                    {isRegister ? "Creating account…" : "Signing in…"}
                  </>
                ) : (
                  <>
                    {isRegister
                      ? isHub
                        ? "Register this hub"
                        : "Register as coordinator"
                      : isHub
                      ? "Sign in as hub admin"
                      : "Sign in as coordinator"}
                    <ArrowRight className="h-5 w-5 transition-transform group-hover:translate-x-1" />
                  </>
                )}
              </button>
            </form>

            <div className="mt-6 flex items-center justify-center gap-3 text-sm">
              <span className="text-ink/55">
                {isRegister ? "Already have an account?" : "New to SEG Attendance?"}
              </span>
              <button
                type="button"
                onClick={() => changeMode(isRegister ? "login" : "register")}
                className="font-semibold text-brand-700 link-underline"
              >
                {isRegister ? "Sign in instead" : "Create one"}
              </button>
            </div>
            <div className="mt-2 text-center">
              <button
                type="button"
                onClick={() => {
                  localStorage.removeItem("seg_token");
                  localStorage.removeItem("seg_role");
                  localStorage.removeItem("seg_user");
                  toast({ type: "info", title: "Cached session cleared", desc: "Any old login data has been removed from this browser." });
                }}
                className="text-[0.7rem] text-ink/40 underline decoration-ink/20 underline-offset-2 hover:text-ink/60"
              >
                Clear my cached session
              </button>
            </div>
            <p className="mt-2 text-center text-xs text-ink/40">
              Tip: the eye inside the password box reveals what you typed.{" "}
              <Link href="/" className="link-underline text-ink/60">Back home</Link>
            </p>
          </div>
        </main>
      </div>
    </div>
  );
}

function Spark(props: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={props.className}>
      <path d="M12 3v4M12 17v4M3 12h4M17 12h4M6 6l2.5 2.5M15.5 15.5 18 18M18 6l-2.5 2.5M8.5 15.5 6 18" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
    </svg>
  );
}
