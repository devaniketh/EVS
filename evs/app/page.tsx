"use client";

import { useEffect, useRef } from "react";
import kaplay, { KAPLAYCtx, GameObj, Vec2 } from "kaplay";

export default function Game() {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const kRef = useRef<KAPLAYCtx | null>(null);

  useEffect(() => {
    if (!canvasRef.current) return;

    const handleResize = () => {
      if (kRef.current) {
        kRef.current.quit();
      }

      const k = kaplay({
        canvas: canvasRef.current ?? undefined,
        global: false,
        touchToMouse: true,
        background: [0, 0, 0],
      });

      kRef.current = k;

      const run = async () => {
        await document.fonts.load("1rem seriousr2b");

        await Promise.all([
          k.loadSprite("road", "/sprites/road.jpg"),
          k.loadSprite("eth", "/sprites/eth-auto.png"),
          k.loadSprite("sol", "/sprites/sol-auto.png"),
          k.loadSprite("obstacle", "/sprites/obstacle.png"),
          k.loadSprite("bg", "/sprites/bg.jpg"),
        ]);

        k.scene("menu", () => {
          k.add([
            k.sprite("bg", { width: k.width(), height: k.height() }),
            k.pos(k.center()),
            k.anchor("center"),
            k.z(-1),
          ]);
          k.add([
            k.rect(k.width() * 0.5, k.height() * 0.6),
            k.pos(k.center()),
            k.anchor("center"),
            k.color(0, 0, 0),
            k.opacity(0.7),
          ]);
          k.add([
            k.text("Eth vs Sol", { size: 90, font: "seriousr2b" }),
            k.pos(k.center().x, k.center().y - 120),
            k.anchor("center"),
          ]);

          const addButton = (txt: string, p: Vec2, f: () => void) => {
            const btn = k.add([
              k.rect(600, 60, { radius: 8 }),
              k.pos(p),
              k.area({ cursor: "pointer" }),
              k.anchor("center"),
              k.color(255, 255, 255),
            ]);

            btn.add([
              k.text(txt, { font: "seriousr2b" }),
              k.anchor("center"),
              k.color(0, 0, 0),
            ]);

            btn.onHoverUpdate(() => {
              btn.color = k.rgb(200, 200, 200);
            });

            btn.onHoverEnd(() => {
              btn.color = k.rgb(255, 255, 255);
            });

            btn.onClick(f);
            return btn;
          };

          addButton("Play (p)", k.vec2(k.center().x, k.center().y), () =>
            k.go("main")
          );
          addButton(
            "Instructions (i)",
            k.vec2(k.center().x, k.center().y + 80),
            () => k.go("instructions")
          );

          k.onKeyPress("p", () => k.go("main"));
          k.onKeyPress("i", () => k.go("instructions"));
        });

        k.scene("instructions", () => {
          k.add([
            k.sprite("bg", { width: k.width(), height: k.height() }),
            k.pos(k.center()),
            k.anchor("center"),
            k.z(-1),
          ]);
          k.add([
            k.rect(k.width() * 0.6, k.height() * 0.7),
            k.pos(k.center()),
            k.anchor("center"),
            k.color(0, 0, 0),
            k.opacity(0.7),
          ]);
          k.add([
            k.text("Instructions", { size: 60, font: "seriousr2b" }),
            k.pos(k.center().x, k.center().y - 120),
            k.anchor("center"),
          ]);

          k.add([
            k.text("Up/Down Arrows to Move", { size: 24, font: "seriousr2b" }),
            k.pos(k.center().x, k.center().y - 40),
            k.anchor("center"),
          ]);
          k.add([
            k.text("Avoid the Obstacles!", { size: 24, font: "seriousr2b" }),
            k.pos(k.center().x, k.center().y),
            k.anchor("center"),
          ]);
          k.add([
            k.text("Speed increases every 10m!", {
              size: 24,
              font: "seriousr2b",
            }),
            k.pos(k.center().x, k.center().y + 40),
            k.anchor("center"),
          ]);

          const addButton = (txt: string, p: Vec2, f: () => void) => {
            const btn = k.add([
              k.rect(600, 60, { radius: 8 }),
              k.pos(p),
              k.area({ cursor: "pointer" }),
              k.anchor("center"),
              k.color(255, 255, 255),
            ]);

            btn.add([
              k.text(txt, { font: "seriousr2b" }),
              k.anchor("center"),
              k.color(0, 0, 0),
            ]);

            btn.onHoverUpdate(() => {
              btn.color = k.rgb(200, 200, 200);
            });

            btn.onHoverEnd(() => {
              btn.color = k.rgb(255, 255, 255);
            });

            btn.onClick(f);
            return btn;
          };

          addButton(
            "Back (esc)",
            k.vec2(k.center().x, k.center().y + 120),
            () => k.go("menu")
          );
          k.onKeyPress("escape", () => k.go("menu"));
        });

        k.scene("gameover", () => {
          k.add([
            k.sprite("bg", { width: k.width(), height: k.height() }),
            k.pos(k.center()),
            k.anchor("center"),
            k.z(-1),
          ]);
          k.add([
            k.rect(k.width() * 0.5, k.height() * 0.6),
            k.pos(k.center()),
            k.anchor("center"),
            k.color(0, 0, 0),
            k.opacity(0.7),
          ]);
          k.add([
            k.text("Game Over", { size: 90, font: "seriousr2b" }),
            k.pos(k.center().x, k.center().y - 120),
            k.anchor("center"),
          ]);

          const addButton = (txt: string, p: Vec2, f: () => void) => {
            const btn = k.add([
              k.rect(600, 60, { radius: 8 }),
              k.pos(p),
              k.area({ cursor: "pointer" }),
              k.anchor("center"),
              k.color(255, 255, 255),
            ]);

            btn.add([
              k.text(txt, { font: "seriousr2b" }),
              k.anchor("center"),
              k.color(0, 0, 0),
            ]);

            btn.onHoverUpdate(() => {
              btn.color = k.rgb(200, 200, 200);
            });

            btn.onHoverEnd(() => {
              btn.color = k.rgb(255, 255, 255);
            });

            btn.onClick(f);
            return btn;
          };

          addButton("Restart (r)", k.vec2(k.center().x, k.center().y), () =>
            k.go("main")
          );
          addButton(
            "Main Menu (esc)",
            k.vec2(k.center().x, k.center().y + 80),
            () => k.go("menu")
          );

          k.onKeyPress("r", () => {
            k.go("main");
          });
          k.onKeyPress("escape", () => {
            k.go("menu");
          });
        });

        k.scene("main", () => {
          let gameStarted = false;
          let isCrashing = false;
          let isPaused = false;
          let pauseModal: GameObj | null = null;

          const destroyPauseModal = () => {
            if (pauseModal) {
              pauseModal.destroy();
              pauseModal = null;
            }
            isPaused = false;
          };

          const createPauseModal = () => {
            isPaused = true;
            pauseModal = k.add([k.fixed(), k.z(299)]);

            pauseModal.add([
              k.rect(k.width(), k.height()),
              k.pos(k.center()),
              k.anchor("center"),
              k.color(0, 0, 0),
              k.opacity(0.5),
            ]);

            pauseModal.add([
              k.rect(k.width() * 0.5, k.height() * 0.6),
              k.pos(k.center()),
              k.anchor("center"),
              k.color(0, 0, 0),
              k.opacity(0.7),
            ]);

            pauseModal.add([
              k.text("Are you sure?", { size: 60, font: "seriousr2b" }),
              k.pos(k.center().x, k.center().y - 100),
              k.anchor("center"),
            ]);

            const createBtn = (txt: string, p: Vec2, f: () => void) => {
              if (!pauseModal) return;
              const btn = pauseModal.add([
                k.rect(600, 60, { radius: 8 }),
                k.pos(p),
                k.area({ cursor: "pointer" }),
                k.anchor("center"),
                k.color(255, 255, 255),
              ]);
              btn.add([
                k.text(txt, { font: "seriousr2b" }),
                k.anchor("center"),
                k.color(0, 0, 0),
              ]);
              btn.onHoverUpdate(() => {
                btn.color = k.rgb(200, 200, 200);
              });
              btn.onHoverEnd(() => {
                btn.color = k.rgb(255, 255, 255);
              });
              btn.onClick(f);
            };

            createBtn(
              "Yes (y)",
              k.vec2(k.center().x, k.center().y + 80),
              () => {
                destroyPauseModal();
                k.go("menu");
              }
            );
            createBtn(
              "Cancel (c)",
              k.vec2(k.center().x, k.center().y),
              destroyPauseModal
            );
          };

          k.onKeyPress("escape", () => {
            if (!gameStarted || isCrashing) return;
            if (isPaused) {
              destroyPauseModal();
            } else {
              createPauseModal();
            }
          });

          k.onKeyPress("c", () => {
            if (isPaused) {
              destroyPauseModal();
            }
          });

          k.onKeyPress("y", () => {
            if (isPaused) {
              destroyPauseModal();
              k.go("menu");
            }
          });

          const countdownBg = k.add([
            k.rect(300, 200, { radius: 16 }),
            k.pos(k.center()),
            k.anchor("center"),
            k.color(0, 0, 0),
            k.opacity(0.7),
            k.z(199),
            k.fixed(),
          ]);

          const countdownText = k.add([
            k.text("3", { size: 120, font: "seriousr2b" }),
            k.pos(k.center()),
            k.anchor("center"),
            k.z(200),
            k.fixed(),
          ]);

          const startCountdown = async () => {
            await k.wait(1);
            countdownText.text = "2";
            await k.wait(1);
            countdownText.text = "1";
            await k.wait(1);
            countdownText.text = "GO!";
            await k.wait(0.5);
            countdownText.destroy();
            countdownBg.destroy();
            gameStarted = true;
          };

          startCountdown();

          const laneHeight = k.height() / 3;
          const laneY = (i: number) => laneHeight * (i + 0.5);

          let obstacleSpeed = 280;
          const MIN_LANE_GAP = Math.max(260, k.width() * 0.45);

          for (let i = 0; i < 3; i++) {
            for (let j = 0; j < 2; j++) {
              const road = k.add([
                k.sprite("road", {
                  tiled: true,
                  width: k.width(),
                  height: k.height() / 3,
                }),
                k.pos(j * k.width(), i * laneHeight),
                k.z(-10),
              ]);
              road.onUpdate(() => {
                if (!gameStarted || isPaused) return;
                road.move(-obstacleSpeed, 0);
                if (road.pos.x <= -k.width()) road.pos.x += k.width() * 2;
              });
            }
          }

          const ethStartX = Math.min(320, k.width() * 0.35);

          const eth = k.add([
            k.sprite("eth"),
            k.anchor("center"),
            k.area(),
            k.pos(ethStartX, laneY(1)),
            k.scale(0.15),
            k.z(2),
            k.rotate(0),
            "player",
            { lane: 1, pid: "eth" as const },
          ]);

          const trailX = Math.min(Math.max(k.width() * 0.25, 200), 320);

          const sol = k.add([
            k.sprite("sol"),
            k.anchor("center"),
            k.area(),
            k.pos(ethStartX - trailX, laneY(1)),
            k.scale(0.15),
            k.z(1),
            { lane: 1, pid: "sol" as const },
          ]);

          const clampLane = (n: number) => Math.max(0, Math.min(2, n));

          const followDelay = 0.35;
          const laneEvents: { time: number; lane: number }[] = [];
          const laneNextSpawn = [0, 0, 0];
          const lanes = [0, 1, 2];

          const changeLane = (delta: number) => {
            if (!gameStarted || isPaused) return;
            const newLane = clampLane(eth.lane + delta);
            if (newLane === eth.lane) return;
            eth.lane = newLane;
            laneEvents.push({ time: k.time() + followDelay, lane: eth.lane });
          };

          k.onKeyPress("up", () => {
            if (!gameStarted || isPaused) return;
            changeLane(-1);
          });
          k.onKeyPress("down", () => {
            if (!gameStarted || isPaused) return;
            changeLane(1);
          });

          k.onUpdate(() => {
            if (!gameStarted || isPaused) return;

            sol.pos.x = eth.pos.x - trailX;

            const bobFrequency = 4;
            const bobAmount = 3;
            const lerpSpeed = 10;

            const ethTargetY =
              laneY(eth.lane) + Math.sin(k.time() * bobFrequency) * bobAmount;
            const solTargetY =
              laneY(sol.lane) - Math.sin(k.time() * bobFrequency) * bobAmount;

            eth.pos.y = k.lerp(eth.pos.y, ethTargetY, k.dt() * lerpSpeed);
            sol.pos.y = k.lerp(sol.pos.y, solTargetY, k.dt() * lerpSpeed);

            const now = k.time();
            while (laneEvents.length && laneEvents[0].time <= now) {
              const evt = laneEvents.shift()!;
              sol.lane = evt.lane;
            }
          });

          let score = 0;
          k.add([
            k.rect(120, 40, { radius: 8 }),
            k.pos(10, 10),
            k.color(0, 0, 0),
            k.opacity(0.7),
            k.z(99),
            k.fixed(),
          ]);
          const scoreText = k.add([
            k.text("0 m", { font: "seriousr2b" }),
            k.pos(70, 30),
            k.anchor("center"),
            k.z(100),
            k.fixed(),
          ]);
          k.loop(1, () => {
            if (!gameStarted || isPaused) return;
            score += 1;
            scoreText.text = `${score} m`;
            if (score > 0 && score % 10 === 0) {
              obstacleSpeed += 250;
            }
          });

          const spawnObstaclePair = () => {
            if (!gameStarted || isPaused) return;
            const now = k.time();
            const availableLanes = lanes.filter(
              (lane) => now >= laneNextSpawn[lane]
            );

            if (availableLanes.length < 2) return;

            const shuffled = availableLanes.sort(() => 0.5 - Math.random());
            const lanesToSpawn = shuffled.slice(0, 2);

            for (const lane of lanesToSpawn) {
              laneNextSpawn[lane] = now + MIN_LANE_GAP / obstacleSpeed;
              const o = k.add([
                k.sprite("obstacle"),
                k.anchor("center"),
                k.area(),
                k.pos(k.width() + 100, laneY(lane)),
                k.scale(0.8),
                k.z(0),
                "obstacle",
                { lane },
              ]);
              o.onUpdate(() => {
                if (!gameStarted || isPaused) return;
                o.move(-obstacleSpeed, 0);
                if (o.pos.x < -80) o.destroy();
              });
            }
          };

          k.loop(1.2, () => {
            if (!gameStarted || isPaused) return;
            spawnObstaclePair();
          });

          k.onCollide("player", "obstacle", async (player) => {
            if (isCrashing) return;
            isCrashing = true;
            gameStarted = false;

            await k.tween(
              player.angle,
              45,
              0.5,
              (val) => (player.angle = val),
              k.easings.easeOutQuad
            );

            k.go("gameover");
          });
        });

        k.go("menu");
      };

      run();
    };

    handleResize();
    window.addEventListener("resize", handleResize);

    return () => {
      window.removeEventListener("resize", handleResize);
      if (kRef.current) {
        kRef.current.quit();
      }
    };
  }, []);

  return (
    <div className="flex min-w-screen min-h-screen">
      <canvas ref={canvasRef} />
    </div>
  );
}
