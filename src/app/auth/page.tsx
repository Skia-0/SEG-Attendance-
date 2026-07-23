import type { Metadata } from "next";
import { ToastProvider, ErrorBoundary } from "@/components/ui";
import AuthShell from "@/components/AuthShell";

export const metadata: Metadata = {
  title: "Sign in or register · SEG Attendance",
};

type Mode = "login" | "register";
type Role = "hub" | "coordinator";

export default async function AuthPage({
  searchParams,
}: {
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}) {
  const sp = await searchParams;
  const rawMode = Array.isArray(sp.mode) ? sp.mode[0] : sp.mode;
  const rawRole = Array.isArray(sp.role) ? sp.role[0] : sp.role;
  const mode: Mode = rawMode === "register" ? "register" : "login";
  const role: Role = rawRole === "coordinator" ? "coordinator" : "hub";

  return (
    <ErrorBoundary fallbackTitle="The sign-in screen hit a snag">
      <ToastProvider>
        <AuthShell initialMode={mode} initialRole={role} />
      </ToastProvider>
    </ErrorBoundary>
  );
}
