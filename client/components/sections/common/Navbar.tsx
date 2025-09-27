"use client";

import Link from "next/link";
import {
  CaretDownIcon,
  GameControllerIcon,
  WalletIcon,
} from "@phosphor-icons/react";

export default function Navbar() {
  return (
    <header className="fixed top-4 left-0 right-0 w-full z-50">
      <div className="container mx-auto">
        <div className="mx-4 bg-background/40 backdrop-blur-[5px] border-2 border-foreground/15 flex items-center justify-between py-4 px-8">
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
