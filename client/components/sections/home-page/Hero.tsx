"use client";

import { useRef } from "react";
import gsap from "gsap";
import { useGSAP } from "@gsap/react";
import { SplitText } from "gsap/all";
import Image from "next/image";
import bg from "@/public/images/hero-bg.png";

gsap.registerPlugin(SplitText);

export default function Hero() {
  const headingRef = useRef<HTMLHeadingElement>(null);

  useGSAP(() => {
    const tl = gsap.timeline();
    const headingSplit = new SplitText(headingRef.current, { type: "lines" });

    tl.from(headingSplit.lines, {
      y: 30,
      filter: "blur(5px)",
      stagger: 0.2,
      opacity: 0,
      duration: 0.8,
      ease: "sine.inOut",
    });
  });

  return (
    <section className="relative">
      <Image
        src={bg}
        alt="hero-bg"
        className="absolute -z-10 object-center object-cover mask-b-from-50% select-none"
      />
      <div className="container mx-auto">
        <div className="flex flex-col gap-8 items-start justify-center min-h-screen mx-10">
          <h1
            ref={headingRef}
            className="font-head text-6xl uppercase font-bold leading-18">
            <div className="inline-flex items-center justify-center">
              Unlock{" "}
              <svg
                width="48"
                height="48"
                fill="#fff"
                viewBox="0 0 256 256"
                className="ml-3">
                <path d="M208,76H100V56a28,28,0,0,1,28-28c13.51,0,25.65,9.62,28.24,22.39a12,12,0,1,0,23.52-4.78C174.87,21.5,153.1,4,128,4A52.06,52.06,0,0,0,76,56V76H48A20,20,0,0,0,28,96V208a20,20,0,0,0,20,20H208a20,20,0,0,0,20-20V96A20,20,0,0,0,208,76Zm-4,128H52V100H204Zm-88-30.34V180a12,12,0,0,0,24,0v-6.34a32,32,0,1,0-24,0ZM128,136a8,8,0,1,1-8,8A8,8,0,0,1,128,136Z"></path>
              </svg>
            </div>{" "}
            <br />{" "}
            <div className="inline-flex items-center justify-center">
              Onchain
              <svg
                width="48"
                height="48"
                fill="#fff"
                className="mx-3"
                viewBox="0 0 256 256">
                <path d="M236,208a12,12,0,0,1-12,12H32a12,12,0,0,1-12-12V48a12,12,0,0,1,24,0v85.55L88.1,95a12,12,0,0,1,15.1-.57l56.22,42.16L216.1,87A12,12,0,1,1,231.9,105l-64,56a12,12,0,0,1-15.1.57L96.58,119.44,44,165.45V196H224A12,12,0,0,1,236,208Z"></path>
              </svg>
              Rewards
            </div>
            <br /> For <span className="text-accent">Leverage</span> Trading
          </h1>
          <p className="text-xl max-w-6xl">
            Play games onchain, earn liquidity as rewards, and save your trades
            today. Experience the next generation of DeFi gaming—compete, earn,
            and maximize your trading potential with seamless onchain rewards
            and innovative leverage trading opportunities.
          </p>
          <div className="flex gap-4 items-center">
            <button className="bg-foreground text-background px-4 py-2 font-head uppercase font-bold text-lg border-2 hover:text-foreground hover:bg-transparent active:scale-97 duration-300">
              Start Now
            </button>
            <button className="bg-foreground text-background px-4 py-2 font-head uppercase font-bold text-lg border-2 hover:text-foreground hover:bg-transparent active:scale-97 duration-300">
              Know More
            </button>
          </div>
        </div>
      </div>
    </section>
  );
}
