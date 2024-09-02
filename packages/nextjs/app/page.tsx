import Link from "next/link";
import type { NextPage } from "next";

const TOOLS = [
  {
    emoji: "🌊",
    title: "Liquidity Pools",
    href: "/pools",
    description: "Explore and interact with liquidity pools",
  },
  {
    emoji: "🪝",
    title: "Pool Hooks",
    href: "/hooks",
    description: "Extend liquidity pool functionality with hooks",
  },
];

const Home: NextPage = () => {
  return (
    <div className="flex-grow bg-base-300">
      <div className="max-w-screen-2xl mx-auto">
        <div className="flex items-center flex-col flex-grow py-10 bg-base-300 px-5 lg:px-10">
          <div className="px-5 mb-14">
            <h1 className="text-center text-6xl font-bold mb-14 mt-5">Scaffold Balancer</h1>
            <p className="text-2xl">
              A series of guides and a prototyping tools for creating custom pools that integrate with Balancer v3
            </p>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-10 w-full">
            {TOOLS.map(item => (
              <Link
                className="relative bg-base-200 hover:scale-105 hover:bg-neutral text-2xl text-center p-8 rounded-3xl shadow-lg"
                key={item.href}
                href={item.href}
                passHref
              >
                <div className="text-8xl my-7">{item.emoji}</div>
                <h3 className="text-4xl font-bold mb-5">{item.title}</h3>
                <p className="text-xl mb-0">{item.description}</p>
              </Link>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

export default Home;
