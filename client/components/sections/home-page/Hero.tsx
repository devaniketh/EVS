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
  const video1Ref = useRef<HTMLDivElement>(null);
  const video2Ref = useRef<HTMLDivElement>(null);

  useGSAP(() => {
    const tl = gsap.timeline();
    const headingSplit = new SplitText(headingRef.current, { type: "lines" });

    tl.from(headingSplit.lines, {
      y: 30,
      filter: "blur(5px)",
      stagger: 0.5,
      opacity: 0,
      duration: 2,
      ease: "power1.inOut",
    });

    tl.from(video1Ref.current, {
      width: 0,
      marginLeft: 0,
      opacity: 0,
      duration: 1.5,
      delay: 0.2,
      ease: "back.inOut",
    });

    tl.from(
      video2Ref.current,
      {
        width: 0,
        marginLeft: 10,
        marginRight: 10,
        opacity: 0,
        duration: 1.5,
        delay: 0.3,
        ease: "back.inOut",
      },
      "<"
    );
  });

  return (
    <section className="relative">
      <Image
        src={bg}
        alt="hero-bg"
        className="absolute -z-10 object-center object-cover mask-b-from-50%"
      />
      <div className="container mx-auto">
        <div className="flex flex-col gap-8 items-start justify-center min-h-screen">
          <video src="/videos/hero-bg.mov" autoPlay loop className="size-10" />
          <h1
            ref={headingRef}
            className="font-head text-6xl uppercase font-bold leading-18">
            <div className="inline-flex items-center justify-center">
              Unlock{" "}
              <div
                ref={video1Ref}
                className="w-30 h-11 ml-6 origin-center overflow-hidden bg-foreground flex items-center justify-center">
                <video
                  src="videos/unlock.mp4"
                  autoPlay
                  loop
                  className="object-cover h-[90%] w-[97%]"
                />
              </div>
            </div>{" "}
            <br />{" "}
            <div className="inline-flex items-center justify-center">
              Onchain{" "}
              <div
                ref={video2Ref}
                className="w-30 h-11 mx-5 origin-center overflow-hidden bg-foreground flex items-center justify-center">
                <video
                  src="videos/graph-up.mp4"
                  autoPlay
                  loop
                  className="object-cover h-[90%] w-[97%]"
                />
              </div>
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
            <button className="bg-foreground text-background px-4 py-2 font-head uppercase font-bold text-lg border-2 hover:text-foreground hover:bg-background active:scale-97 duration-300">
              Start Trading Now
            </button>
            <button className="bg-foreground text-background px-4 py-2 font-head uppercase font-bold text-lg border-2 hover:text-foreground hover:bg-background active:scale-97 duration-300">
              Know More
            </button>
          </div>
        </div>
      </div>
    </section>
  );
}
