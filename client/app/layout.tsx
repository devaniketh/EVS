import "@/styles.css";
import type { Metadata } from "next";
import { Instrument_Sans, Instrument_Serif } from "next/font/google";

const insans = Instrument_Sans({
  weight: "variable",
  variable: "--font-insans",
  subsets: ["latin"],
});

const inserif = Instrument_Serif({
  weight: "400",
  variable: "--font-inserif",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "",
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
        className={`antialiased ${insans.variable} ${inserif.variable} font-sans`}>
        {children}
      </body>
    </html>
  );
}
