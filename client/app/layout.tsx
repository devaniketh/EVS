import "@/styles.css";
import type { Metadata } from "next";

import Navbar from "@/components/sections/common/Navbar";
import SmoothScroll from "@/components/sections/common/SmoothScroll";

export const metadata: Metadata = {
  title: "Zathura",
  description: "",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body
        className={`antialiased font-sans selection:bg-accent selection:text-white`}>
        <Navbar />
        <SmoothScroll>{children}</SmoothScroll>
      </body>
    </html>
  );
}
