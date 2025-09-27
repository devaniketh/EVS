"use client";

import Link from "next/link";
import { useEffect, useRef, useState } from "react";
import { gsap } from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import {
  CaretDownIcon,
  GameControllerIcon,
  WalletIcon,
} from "@phosphor-icons/react";
import { useGSAP } from "@gsap/react";

gsap.registerPlugin(ScrollTrigger);

export default function Navbar() {
  const navRef = useRef<HTMLDivElement>(null);
  const [scrolled, setScrolled] = useState(false);

  useGSAP(() => {
    if (typeof window !== "undefined") {
      setScrolled(window.scrollY > 10);
    }

    ScrollTrigger.create({
      trigger: document.body,
      start: "top -10",
      onEnter: () => setScrolled(true),
      onLeaveBack: () => setScrolled(false),
    });
  }, []);
  return (
    <header className="fixed top-4 left-0 right-0 w-full z-50">
      <div className="container mx-auto">
        <div
          ref={navRef}
          className={`flex items-center justify-between py-4 px-8 border-2 transition-all duration-800 mx-auto ${
            scrolled
              ? "bg-background/50 backdrop-blur-[5px] border-foreground/15 max-w-6xl"
              : "bg-transparent border-transparent max-w-full"
          }`}>
          <Link
            href={"/"}
            className="text-4xl font-head uppercase font-bold group select-none">
            <span className="drop-shadow-sm drop-shadow-transparent group-hover:drop-shadow-foreground duration-300">
              Z
            </span>
            <span className="text-accent drop-shadow-sm drop-shadow-accent">
              a
            </span>
            <span className="drop-shadow-sm drop-shadow-transparent group-hover:drop-shadow-foreground duration-300">
              thur
            </span>
            <span className="text-accent drop-shadow-sm drop-shadow-accent">
              a
            </span>
          </Link>
          <div className="flex gap-8 items-center select-none">
            <div className="font-head uppercase font-bold inline-flex gap-1 items-center">
              Sponsers
              <CaretDownIcon size={20} weight="bold" />
            </div>
            <div className="h-10 w-0.5 bg-foreground/15" />
            <Link
              href={"/game"}
              className="font-head uppercase font-bold inline-flex gap-2 items-center">
              <GameControllerIcon size={24} weight="bold" />
              Play
            </Link>
            <button className="font-head uppercase font-bold inline-flex gap-2 items-center">
              <WalletIcon size={24} weight="bold" />
              Connect
            </button>
          </div>
        </div>
      </div>
    </header>
  );
}
