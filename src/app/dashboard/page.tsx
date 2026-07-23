import type { Metadata } from "next";
import { ToastProvider, ErrorBoundary } from "@/components/ui";
import DashboardShell from "@/components/DashboardShell";

export const metadata: Metadata = { title: "Dashboard · SEG Attendance" };

export default function DashboardPage() {
  return (
    <ErrorBoundary fallbackTitle="The dashboard hit a snag">
      <ToastProvider>
        <DashboardShell />
      </ToastProvider>
    </ErrorBoundary>
  );
}
