"use client";
import {
  Component,
  createContext,
  useCallback,
  useContext,
  useEffect,
  useId,
  useMemo,
  useRef,
  useState,
  type ErrorInfo,
  type ReactNode,
  type Ref,
} from "react";
import type { ElementType } from "react";
import { Eye, EyeOff, Lock, Check } from "./icons";
import { passwordStrength } from "@/lib/auth";

/* ---------------- Error boundary ---------------- */
export class ErrorBoundary extends Component<
  { children: ReactNode; fallbackTitle?: string },
  { error: Error | null }
> {
  state = { error: null as Error | null };
  static getDerivedStateFromError(error: Error) {
    return { error };
  }
  componentDidCatch(error: Error, info: ErrorInfo) {
    // eslint-disable-next-line no-console
    console.error("[SEG] render error:", error, info);
  }
  render() {
    if (!this.state.error) return this.props.children;
    const msg = this.state.error.message || String(this.state.error);
    return (
      <div className="grid min-h-screen place-items-center bg-paper px-6 text-ink">
        <div className="w-full max-w-md rounded-[1.6rem] border border-ember/30 bg-white p-7 shadow-xl anim-pop">
          <span className="grid h-11 w-11 place-items-center rounded-2xl bg-ember/12 font-display text-xl font-extrabold text-ember">!</span>
          <h1 className="mt-4 font-display text-2xl font-extrabold tracking-tight">
            {this.props.fallbackTitle ?? "The form hit a snag"}
          </h1>
          <p className="mt-2 text-sm text-ink/65">
            Something threw while rendering this screen. Your data is fine — this is a UI fault, not a server one.
          </p>
          <pre className="mt-4 max-h-40 overflow-auto rounded-xl bg-ink/95 p-3 font-mono text-[0.72rem] leading-relaxed text-brand-300">
            {msg}
          </pre>
          <div className="mt-5 flex flex-wrap gap-2.5">
            <button
              onClick={() => this.setState({ error: null })}
              className="rounded-full bg-brand px-4 py-2 text-sm font-bold text-[#1a0f02]"
            >
              Try again
            </button>
            <button
              onClick={() => window.location.reload()}
              className="rounded-full border border-ink/15 px-4 py-2 text-sm font-semibold"
            >
              Reload page
            </button>
            <a href="/" className="rounded-full border border-ink/15 px-4 py-2 text-sm font-semibold link-underline">
              Go home
            </a>
          </div>
        </div>
      </div>
    );
  }
}

/* ---------------- Scroll reveal ---------------- */
export function Reveal({
  children,
  className = "",
  delay = 0,
  as: Tag = "div",
}: {
  children: ReactNode;
  className?: string;
  delay?: number;
  as?: ElementType;
}) {
  const ref = useRef<HTMLElement | null>(null);
  const [shown, setShown] = useState(false);
  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const io = new IntersectionObserver(
      (entries) => {
        entries.forEach((e) => {
          if (e.isIntersecting) {
            setShown(true);
            io.unobserve(e.target);
          }
        });
      },
      { threshold: 0.15 }
    );
    io.observe(el);
    return () => io.disconnect();
  }, []);
  const Comp = Tag as ElementType;
  return (
    <Comp
      ref={ref as never}
      className={`reveal ${shown ? "is-visible" : ""} ${className}`}
      style={{ transitionDelay: `${delay}ms` }}
    >
      {children}
    </Comp>
  );
}

/* ---------------- Segmented control ---------------- */
export function Segmented<T extends string>({
  options,
  value,
  onChange,
  tone = "light",
  name,
}: {
  options: { value: T; label: string; icon?: ReactNode }[];
  value: T;
  onChange: (v: T) => void;
  tone?: "light" | "ink";
  name?: string;
}) {
  const idx = Math.max(0, options.findIndex((o) => o.value === value));
  const n = options.length;
  const isInk = tone === "ink";
  return (
    <div
      role="tablist"
      className={`seg-track ${isInk ? "seg-track-ink" : ""} relative grid rounded-2xl p-1`}
      style={{ gridTemplateColumns: `repeat(${n}, minmax(0, 1fr))` }}
    >
      <span
        aria-hidden
        className={`absolute top-1 bottom-1 rounded-xl transition-[left] duration-300 ease-[cubic-bezier(0.2,0.9,0.25,1)] ${
          isInk ? "bg-brand" : "bg-ink"
        }`}
        style={{ left: `${(idx * 100) / n}%`, width: `calc(${100 / n}% - 0px)` }}
      />
      {options.map((o) => {
        const active = o.value === value;
        return (
          <button
            key={o.value}
            type="button"
            role="tab"
            aria-selected={active}
            name={name}
            onClick={() => onChange(o.value)}
            className={`relative z-10 flex items-center justify-center gap-2 rounded-xl px-3 py-2.5 text-sm font-semibold transition-colors duration-200 ${
              active
                ? isInk
                  ? "text-ink"
                  : "text-paper"
                : isInk
                ? "text-white/70 hover:text-white"
                : "text-ink/60 hover:text-ink"
            }`}
          >
            {o.icon && <span className="h-4 w-4">{o.icon}</span>}
            <span>{o.label}</span>
          </button>
        );
      })}
    </div>
  );
}

/* ---------------- Field shell ---------------- */
export function Field({
  label,
  htmlFor,
  icon,
  hint,
  error,
  children,
  tone = "light",
}: {
  label: string;
  htmlFor?: string;
  icon?: ReactNode;
  hint?: ReactNode;
  error?: string;
  children: ReactNode;
  tone?: "light" | "ink";
}) {
  const isInk = tone === "ink";
  return (
    <div className="block">
      <label htmlFor={htmlFor} className="block">
        <span
          className={`mb-1.5 flex items-center gap-1.5 text-[0.72rem] font-semibold uppercase tracking-[0.12em] ${
            isInk ? "text-white/60" : "text-ink/55"
          }`}
        >
          {icon && <span className="h-3.5 w-3.5 text-brand">{icon}</span>}
          {label}
        </span>
        {children}
      </label>
      {error ? (
        <span role="alert" className="mt-1.5 flex items-start gap-1.5 text-xs font-medium text-ember anim-pop">
          <span className="font-display font-extrabold leading-none">!</span>
          {error}
        </span>
      ) : hint ? (
        <span className={`mt-1.5 block text-xs ${isInk ? "text-white/50" : "text-ink/50"}`}>{hint}</span>
      ) : null}
    </div>
  );
}

/* ---------------- Password field (UNCONTROLLED) ----------------
 * The <input> is intentionally uncontrolled (no `value` prop) so native typing
 * always works at the DOM level, independent of React's render cycle. We mirror
 * the value up through onMirror purely for the strength meter; we never write
 * it back into the input. The eye toggle flips the input `type` only.
 */
export function PasswordField({
  id,
  name = "password",
  inputRef,
  onMirror,
  placeholder = "••••••••",
  tone = "light",
  showStrength = false,
  autoComplete = "current-password",
  strengthValue = "",
}: {
  id: string;
  name?: string;
  inputRef?: Ref<HTMLInputElement>;
  onMirror?: (v: string) => void;
  placeholder?: string;
  tone?: "light" | "ink";
  showStrength?: boolean;
  autoComplete?: string;
  strengthValue?: string;
}) {
  const [show, setShow] = useState(false);
  const strength = useMemo(() => passwordStrength(strengthValue), [strengthValue]);
  const isInk = tone === "ink";
  return (
    <div>
      <div className="relative">
        <span className={`pointer-events-none absolute left-3.5 top-1/2 h-[18px] w-[18px] -translate-y-1/2 ${isInk ? "text-white/45" : "text-ink/40"}`}>
          <Lock className="h-full w-full" />
        </span>
        <input
          ref={inputRef}
          id={id}
          name={name}
          type={show ? "text" : "password"}
          inputMode="text"
          autoComplete={autoComplete}
          placeholder={placeholder}
          onChange={(e) => onMirror?.(e.target.value)}
          className={`field ${isInk ? "field-ink" : ""} pl-11 pr-12`}
        />
        <button
          type="button"
          tabIndex={-1}
          aria-label={show ? "Hide password" : "Show password"}
          aria-pressed={show}
          // preventDefault on mousedown keeps focus/selection in the password
          // field while the eye toggles — no caret jump, no label quirk.
          onMouseDown={(e) => e.preventDefault()}
          onClick={() => setShow((s) => !s)}
          className={`group absolute right-2 top-1/2 grid h-9 w-9 -translate-y-1/2 place-items-center rounded-lg transition-colors ${
            isInk ? "text-white/55 hover:bg-white/10 hover:text-white" : "text-ink/45 hover:bg-brand-100 hover:text-brand-700"
          }`}
        >
          <span className="h-[19px] w-[19px] transition-transform duration-200 group-active:scale-90">
            {show ? <EyeOff className="h-full w-full" /> : <Eye className="h-full w-full" />}
          </span>
        </button>
      </div>
      {showStrength && strengthValue.length > 0 && (
        <div className="mt-2 flex items-center gap-2">
          <div className="flex h-1.5 flex-1 gap-1">
            {[0, 1, 2, 3].map((i) => (
              <span
                key={i}
                className={`h-full flex-1 rounded-full transition-colors duration-300 ${
                  i < strength.score
                    ? strength.score <= 1
                      ? "bg-ember"
                      : strength.score === 2
                      ? "bg-brand"
                      : strength.score === 3
                      ? "bg-brand-600"
                      : "bg-palm"
                    : isInk
                    ? "bg-white/12"
                    : "bg-ink/10"
                }`}
              />
            ))}
          </div>
          <span className={`w-16 text-right text-[0.7rem] font-semibold uppercase tracking-wide ${isInk ? "text-white/60" : "text-ink/55"}`}>
            {strength.label}
          </span>
        </div>
      )}
    </div>
  );
}

/* ---------------- Spinner ---------------- */
export function Spinner({ className = "" }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" className={`anim-spin-slow ${className}`} style={{ animationDuration: "0.9s" }} fill="none">
      <circle cx="12" cy="12" r="9" stroke="currentColor" strokeOpacity="0.25" strokeWidth="3" />
      <path d="M21 12a9 9 0 0 0-9-9" stroke="currentColor" strokeWidth="3" strokeLinecap="round" />
    </svg>
  );
}

/* ---------------- Toasts ---------------- */
type Toast = { id: number; type: "success" | "error" | "info"; title: string; desc?: string };
const ToastCtx = createContext<(t: Omit<Toast, "id">) => void>(() => {});
export function useToast() {
  return useContext(ToastCtx);
}
export function ToastProvider({ children }: { children: ReactNode }) {
  const [items, setItems] = useState<Toast[]>([]);
  const push = useCallback((t: Omit<Toast, "id">) => {
    const id = Date.now() + Math.random();
    setItems((s) => [...s, { ...t, id }]);
    setTimeout(() => setItems((s) => s.filter((x) => x.id !== id)), 4800);
  }, []);
  const value = useMemo(() => push, [push]);
  return (
    <ToastCtx.Provider value={value}>
      {children}
      <div className="pointer-events-none fixed right-4 top-4 z-[60] flex w-[min(92vw,360px)] flex-col gap-2.5">
        {items.map((t) => (
          <div
            key={t.id}
            className={`toast-enter pointer-events-auto flex items-start gap-3 rounded-2xl border p-3.5 shadow-[0_18px_40px_rgba(18,11,5,0.18)] backdrop-blur ${
              t.type === "success"
                ? "border-palm/30 bg-white/95"
                : t.type === "error"
                ? "border-ember/40 bg-white/95"
                : "border-brand/30 bg-white/95"
            }`}
          >
            <span
              className={`mt-0.5 grid h-7 w-7 shrink-0 place-items-center rounded-full text-white ${
                t.type === "success" ? "bg-palm" : t.type === "error" ? "bg-ember" : "bg-brand"
              }`}
            >
              {t.type === "error" ? (
                <span className="font-display text-base font-extrabold leading-none">!</span>
              ) : t.type === "success" ? (
                <Check className="h-4 w-4" />
              ) : (
                <span className="font-display text-sm font-extrabold leading-none">i</span>
              )}
            </span>
            <div className="min-w-0">
              <p className="text-sm font-semibold text-ink">{t.title}</p>
              {t.desc && <p className="mt-0.5 text-[0.8rem] leading-snug text-ink/60">{t.desc}</p>}
            </div>
          </div>
        ))}
      </div>
    </ToastCtx.Provider>
  );
}

export function useFieldId(prefix: string) {
  const id = useId();
  return `${prefix}-${id.replace(/:/g, "")}`;
}
