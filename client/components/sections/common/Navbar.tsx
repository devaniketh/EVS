import Link from "next/link";

export default function Navbar() {
  return (
    <header className="fixed top-4 left-0 right-0 w-full z-50">
      <div className="container mx-auto">
        <div className="backdrop-blur-[5px] bg-white/10 border-2 border-white/15 flex items-center justify-between py-4 px-8">
          <Link
            href={"/"}
            className="text-4xl font-head uppercase font-bold group select-none">
            <span className="drop-shadow-sm group-hover:drop-shadow-primary duration-300">
              Z
            </span>
            <span className="text-accent drop-shadow-sm drop-shadow-accent">
              a
            </span>
            <span className="drop-shadow-sm group-hover:drop-shadow-primary duration-300">
              thur
            </span>
            <span className="text-accent drop-shadow-sm drop-shadow-accent">
              a
            </span>
          </Link>
          <div className="flex gap-4 items-center">
            <div className="font-head uppercase font-bold">Docs</div>
            <div className="font-head uppercase font-bold">Sponsers</div>
            <button className="font-head uppercase font-bold">Connect</button>
          </div>
        </div>
      </div>
    </header>
  );
}
