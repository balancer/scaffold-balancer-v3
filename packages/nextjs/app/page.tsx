import Link from "next/link";
import type { NextPage } from "next";

const TOOLS = [
  {
    emoji: "🌊",
    title: "Pools",
    href: "/pools",
    description: "Create and explore custom pools",
  },
  {
    emoji: "🧭",
    title: "Router",
    href: "/router",
    description: "Integrate pools with the smart order router",
  },
  {
    emoji: "📡",
    title: "Subgraph",
    href: "/subgraph",
    description: "Integrate pools with the Balancer subgraph",
  },
];

const Home: NextPage = () => {
  return (
    <>
      <div className="flex items-center flex-col flex-grow py-10 bg-base-300 px-5 lg:px-10">
        <div className="px-5 mb-14">
          <h1 className="text-center text-6xl font-bold mb-14 mt-5">Scaffold-Balancer</h1>
          <p className="text-2xl">
            A series of guides and a prototyping tools for creating custom pools that integrate with Balancer v3
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 2xl:grid-cols-3 gap-10">
          {TOOLS.map(item => (
            <Link
              className="bg-base-100 hover:scale-105 hover:bg-base-200 text-2xl text-center p-8 rounded-3xl"
              key={item.href}
              href={item.href}
              passHref
            >
              <h3 className="text-4xl mb-10">{item.title}</h3>
              <div className="text-8xl mb-10">{item.emoji}</div>
              <p className="text-xl">{item.description}</p>
            </Link>
          ))}
        </div>
      </div>
    </>
  );
};

export default Home;
