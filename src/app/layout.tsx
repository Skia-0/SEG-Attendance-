import type { Metadata } from "next";
import type { ReactNode } from "react";
import "./globals.css";

export const metadata: Metadata = {
  title: "SEG Attendance — Social Enterprise Ghana",
  description:
    "Attendance, cohorts and check-ins for Social Enterprise Ghana hubs and coordinators.",
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <body className="bg-paper text-ink antialiased font-sans">{children}</body>
    </html>
  );
}
