"use client";

export type SessionUser =
  | {
      role: "hub";
      id: string;
      name: string;
      location: string;
      admin_email: string;
      wifi_ssid?: string | null;
    }
  | {
      role: "coordinator";
      id: string;
      full_name: string;
      phone: string;
      hub_id: string;
      hub_name: string;
      hub_location?: string;
    };

const K = { token: "seg_token", role: "seg_role", user: "seg_user" } as const;

export function saveSession(token: string, role: "hub" | "coordinator", user: SessionUser) {
  if (typeof window === "undefined") return;
  localStorage.setItem(K.token, token);
  localStorage.setItem(K.role, role);
  localStorage.setItem(K.user, JSON.stringify(user));
}

export function readSession(): { token: string; role: "hub" | "coordinator"; user: SessionUser | null } | null {
  if (typeof window === "undefined") return null;
  const token = localStorage.getItem(K.token);
  const role = localStorage.getItem(K.role) as "hub" | "coordinator" | null;
  if (!token || !role) return null;
  let user: SessionUser | null = null;
  try {
    user = JSON.parse(localStorage.getItem(K.user) ?? "null");
  } catch {
    user = null;
  }
  return { token, role, user };
}

export function clearSession() {
  if (typeof window === "undefined") return;
  localStorage.removeItem(K.token);
  localStorage.removeItem(K.role);
  localStorage.removeItem(K.user);
}

export function initials(name: string): string {
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return "?";
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
}
