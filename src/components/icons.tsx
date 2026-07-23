import type { SVGProps } from "react";

type P = SVGProps<SVGSVGElement>;
const base = "shrink-0";

export const Eye = (p: P) => (
  <svg viewBox="0 0 24 24" fill="none" className={base} {...p}>
    <path d="M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12Z" stroke="currentColor" strokeWidth="1.8" strokeLinejoin="round" />
    <circle cx="12" cy="12" r="3" stroke="currentColor" strokeWidth="1.8" />
  </svg>
);
export const EyeOff = (p: P) => (
  <svg viewBox="0 0 24 24" fill="none" className={base} {...p}>
    <path d="M3 3l18 18" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
    <path d="M10.6 6.1A9.7 9.7 0 0 1 12 6c6 0 9.5 6 9.5 6a16 16 0 0 1-3.2 3.9M6.2 7.8A16 16 0 0 0 2.5 12S6 18 12 18a9.3 9.3 0 0 0 3.3-.6" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
    <path d="M9.9 9.9a3 3 0 0 0 4.2 4.2" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
  </svg>
);
export const Mail = (p: P) => (
  <svg viewBox="0 0 24 24" fill="none" className={base} {...p}>
    <rect x="3" y="5" width="18" height="14" rx="2.5" stroke="currentColor" strokeWidth="1.8" />
    <path d="m3.5 7 8.5 6 8.5-6" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
  </svg>
);
export const Phone = (p: P) => (
  <svg viewBox="0 0 24 24" fill="none" className={base} {...p}>
    <path d="M6.5 3.5h3l1.5 4-2 1.5a11 11 0 0 0 5 5l1.5-2 4 1.5v3a2 2 0 0 1-2.2 2A16.5 16.5 0 0 1 4.5 5.7 2 2 0 0 1 6.5 3.5Z" stroke="currentColor" strokeWidth="1.8" strokeLinejoin="round" />
  </svg>
);
export const Lock = (p: P) => (
  <svg viewBox="0 0 24 24" fill="none" className={base} {...p}>
    <rect x="4.5" y="10.5" width="15" height="10" rx="2.5" stroke="currentColor" strokeWidth="1.8" />
    <path d="M8 10.5V8a4 4 0 0 1 8 0v2.5" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
    <circle cx="12" cy="15.5" r="1.4" fill="currentColor" />
  </svg>
);
export const User = (p: P) => (
  <svg viewBox="0 0 24 24" fill="none" className={base} {...p}>
    <circle cx="12" cy="8.5" r="3.5" stroke="currentColor" strokeWidth="1.8" />
    <path d="M5 19.5c0-3.6 3.1-6 7-6s7 2.4 7 6" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
  </svg>
);
export const MapPin = (p: P) => (
  <svg viewBox="0 0 24 24" fill="none" className={base} {...p}>
    <path d="M12 21s7-5.6 7-11a7 7 0 1 0-14 0c0 5.4 7 11 7 11Z" stroke="currentColor" strokeWidth="1.8" strokeLinejoin="round" />
    <circle cx="12" cy="10" r="2.5" stroke="currentColor" strokeWidth="1.8" />
  </svg>
);
export const Wifi = (p: P) => (
  <svg viewBox="0 0 24 24" fill="none" className={base} {...p}>
    <path d="M2.5 9.5a14 14 0 0 1 19 0M5.5 13a9.5 9.5 0 0 1 13 0M8.5 16.3a5 5 0 0 1 7 0" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
    <circle cx="12" cy="19.3" r="1.2" fill="currentColor" />
  </svg>
);
export const Building = (p: P) => (
  <svg viewBox="0 0 24 24" fill="none" className={base} {...p}>
    <path d="M4 20.5V5.5a1.5 1.5 0 0 1 1.5-1.5h7A1.5 1.5 0 0 1 14 5.5v15M14 9.5h4.5A1.5 1.5 0 0 1 20 11v9.5M3 20.5h18" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
    <path d="M7 8h3M7 12h3M7 16h3M17 13h0M17 17h0" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
  </svg>
);
export const Check = (p: P) => (
  <svg viewBox="0 0 24 24" fill="none" className={base} {...p}>
    <path d="m4.5 12.5 5 5 10-11" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" />
  </svg>
);
export const ArrowRight = (p: P) => (
  <svg viewBox="0 0 24 24" fill="none" className={base} {...p}>
    <path d="M4 12h15m0 0-6-6m6 6-6 6" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
  </svg>
);
export const Spark = (p: P) => (
  <svg viewBox="0 0 24 24" fill="none" className={base} {...p}>
    <path d="M12 3v4M12 17v4M3 12h4M17 12h4M6 6l2.5 2.5M15.5 15.5 18 18M18 6l-2.5 2.5M8.5 15.5 6 18" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
  </svg>
);
export const Shield = (p: P) => (
  <svg viewBox="0 0 24 24" fill="none" className={base} {...p}>
    <path d="M12 3 5 6v5c0 4.5 3 8 7 10 4-2 7-5.5 7-10V6l-7-3Z" stroke="currentColor" strokeWidth="1.8" strokeLinejoin="round" />
    <path d="m9 12 2 2 4-4" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
  </svg>
);
export const Clock = (p: P) => (
  <svg viewBox="0 0 24 24" fill="none" className={base} {...p}>
    <circle cx="12" cy="12" r="8.5" stroke="currentColor" strokeWidth="1.8" />
    <path d="M12 7.5V12l3 2" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
  </svg>
);
export const Users = (p: P) => (
  <svg viewBox="0 0 24 24" fill="none" className={base} {...p}>
    <circle cx="9" cy="8.5" r="3.2" stroke="currentColor" strokeWidth="1.8" />
    <path d="M3.5 19c0-3.2 2.6-5.3 5.5-5.3s5.5 2.1 5.5 5.3" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
    <path d="M16 6.2a3 3 0 0 1 0 5.6M17 14c2.4.4 4 2.3 4 5" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
  </svg>
);
export const Logout = (p: P) => (
  <svg viewBox="0 0 24 24" fill="none" className={base} {...p}>
    <path d="M14 4H6.5A1.5 1.5 0 0 0 5 5.5v13A1.5 1.5 0 0 0 6.5 20H14M10 12h9m0 0-3-3m3 3-3 3" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
  </svg>
);
export const Chevron = (p: P) => (
  <svg viewBox="0 0 24 24" fill="none" className={base} {...p}>
    <path d="m6 9 6 6 6-6" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
  </svg>
);
export const Nfc = (p: P) => (
  <svg viewBox="0 0 24 24" fill="none" className={base} {...p}>
    <path d="M5 9a9 9 0 0 1 0 6M8 7.5a6 6 0 0 1 0 9M11 6a9.5 9.5 0 0 1 0 12" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
    <rect x="15" y="4" width="5" height="16" rx="1.5" stroke="currentColor" strokeWidth="1.8" />
  </svg>
);
export const Fingerprint = (p: P) => (
  <svg viewBox="0 0 24 24" fill="none" className={base} {...p}>
    <path d="M6 11a6 6 0 0 1 12 0v2M9 12a3 3 0 0 1 6 0v3a6 6 0 0 1-.5 2.4M12 12v4a9 9 0 0 1-.8 3.7M6.5 15a9 9 0 0 0 .8 3.7M15.5 18.5a9 9 0 0 0 .6-2" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
  </svg>
);
