import "@/styles.css";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Zathura | Eth vs Sol",
  description: "The race is real",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className={`antialiased`}>{children}</body>
    </html>
  );
}
