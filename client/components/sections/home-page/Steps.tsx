"use client";

import * as Icons from "@phosphor-icons/react";
import React, { useRef, forwardRef } from "react";
import gsap from "gsap";
import { useGSAP } from "@gsap/react";

interface CardProps {
  className?: string;
  title: string;
  description: string;
  icon: string;
  descRef?: React.RefObject<HTMLParagraphElement | null>;
}

const Card = forwardRef<HTMLDivElement, CardProps>(
  ({ className, title, description, icon, descRef }, ref) => {
    const IconComponent = (Icons as any)[icon];
    return (
      <div
        ref={ref}
        className={
          `relative w-1/3 h-90 border-4 border-foreground/30 overflow-hidden p-6 flex items-end gap-4` +
          (className || "")
        }>
        <IconComponent
          size={300}
          weight="bold"
          className="absolute -top-3 -right-5 -rotate-20 opacity-5"
        />
        <h1 className="font-head uppercase font-bold text-5xl">{title}</h1>
        <p ref={descRef} className="text-right max-w-80 ml-auto opacity-0">
          {description}
        </p>
      </div>
    );
  }
);

export default function Steps() {
  const card1Ref = useRef<HTMLDivElement>(null);
  const card2Ref = useRef<HTMLDivElement>(null);
  const card3Ref = useRef<HTMLDivElement>(null);
  const desc1Ref = useRef<HTMLParagraphElement>(null);
  const desc2Ref = useRef<HTMLParagraphElement>(null);
  const desc3Ref = useRef<HTMLParagraphElement>(null);

  useGSAP(() => {
    const animation1 = gsap
      .timeline({ paused: true })
      .fromTo(
        card1Ref.current,
        {
          width: "33.33%",
        },
        {
          width: "50%",
          ease: "power2.inOut",
          duration: 0.8,
        }
      )
      .fromTo(
        desc1Ref.current,
        {
          opacity: 0,
        },
        {
          opacity: 1,
          duration: 0.5,
        },
        "<0.55"
      );
    const animation2 = gsap
      .timeline({ paused: true })
      .fromTo(
        card2Ref.current,
        {
          width: "33.33%",
        },
        {
          width: "50%",
          ease: "power2.inOut",
          duration: 0.8,
        }
      )
      .fromTo(
        desc2Ref.current,
        {
          opacity: 0,
        },
        {
          opacity: 1,
          duration: 0.5,
        },
        "<0.55"
      );
    const animation3 = gsap
      .timeline({ paused: true })
      .fromTo(
        card3Ref.current,
        {
          width: "33.33%",
        },
        {
          width: "50%",
          ease: "power2.inOut",
          duration: 0.8,
        }
      )
      .fromTo(
        desc3Ref.current,
        {
          opacity: 0,
        },
        {
          opacity: 1,
          duration: 0.5,
        },
        "<0.55"
      );

    card1Ref.current?.addEventListener("mouseenter", () => animation1.play());
    card1Ref.current?.addEventListener("mouseleave", () =>
      animation1.reverse()
    );
    card2Ref.current?.addEventListener("mouseenter", () => animation2.play());
    card2Ref.current?.addEventListener("mouseleave", () =>
      animation2.reverse()
    );
    card3Ref.current?.addEventListener("mouseenter", () => animation3.play());
    card3Ref.current?.addEventListener("mouseleave", () =>
      animation3.reverse()
    );
  });

  return (
    <section className="pb-20">
      <div className="container mx-auto">
        <h1 className="font-head text-6xl uppercase font-bold">How it works</h1>
        <div className="flex justify-center items-center gap-8 mt-10">
          <Card
            className="origin-left"
            ref={card1Ref}
            descRef={desc1Ref}
            icon="GameControllerIcon"
            title="Play"
            description="Lorem ipsum dolor sit amet consectetur adipisicing elit. Fugiat enim, itaque."
          />
          <Card
            className="origin-center"
            ref={card2Ref}
            descRef={desc2Ref}
            icon="CoinIcon"
            title="Earn"
            description="Lorem ipsum dolor sit amet consectetur adipisicing elit. Fugiat enim, itaque."
          />
          <Card
            className="origin-right"
            ref={card3Ref}
            descRef={desc3Ref}
            icon="ChartLine"
            title="Trade"
            description="Lorem ipsum dolor sit amet consectetur adipisicing elit. Fugiat enim, itaque."
          />
        </div>
      </div>
    </section>
  );
}
