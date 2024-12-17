import Link from "next/link";
import type { NextPage } from "next";

const EXAMPLES = [
  {
    emoji: "🌊",
    title: "Custom Pools",
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

const DOCUMENTATION = [
  {
    title: "Build a An Amm",
    href: "https://docs-v3.balancer.fi/build/build-an-amm/create-custom-amm-with-novel-invariant.html",
    description: "Create your own AMM with a novel invariant",
  },
  {
    title: "Build a Hook",
    href: "https://docs-v3.balancer.fi/build/build-a-hook/extend-existing-pool-type.html",
    description: "Extend an existing pool type with hooks",
  },
  {
    title: "Build a Router",
    href: "https://docs-v3.balancer.fi/build/build-a-router/create-custom-router.html",
    description: "Customize interactions with the Vault",
  },
];

const VIDEOS = [
  {
    title: "Intro to Scaffold Balancer",
    href: "https://www.youtube.com/watch?v=m6q5M34ZdXw",
    description: "Learn how to use Scaffold Balancer v3",
  },
  {
    title: "Create Custom AMMs",
    href: "https://www.youtube.com/watch?v=oJAXQCMVdfA",
    description: "Code along demo for creating custom AMMs",
  },
  {
    title: "Create a Hook",
    href: "https://www.youtube.com/watch?v=kaz6duliRPA",
    description: "Code along demo for creating custom AMMs",
  },
];

const Home: NextPage = () => {
  return (
    <div className="flex-grow bg-base-300">
      <div className="max-w-screen-2xl mx-auto">
        <div className="flex items-center flex-col flex-grow py-10 bg-base-300 px-5 lg:px-10 gap-12">
          <div className="px-5">
            <h1 className="text-center text-5xl font-bold mb-10 mt-5">Scaffold Balancer v3</h1>
            <div className="text-2xl w-full">
              A developer friendly tool for prototyping liquidity pools and hooks contracts
            </div>
          </div>

          <div className="w-full">
            <h3 className="text-start text-3xl font-bold mb-5">Examples</h3>
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-10">
              {EXAMPLES.map(item => (
                <Link
                  className="relative bg-base-200 hover:scale-105 transition-all duration-300 text-2xl p-8 rounded-3xl shadow-lg"
                  key={item.href}
                  href={item.href}
                  passHref
                >
                  {/* <div className="text-8xl my-7">{item.emoji}</div> */}
                  <h3 className="text-3xl font-bold mb-5">{item.title}</h3>
                  <div className="text-xl mb-0">{item.description}</div>
                </Link>
              ))}
            </div>
          </div>
          <div className="w-full">
            <h3 className="text-start text-3xl font-bold mb-7">Documentation</h3>
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-10">
              {DOCUMENTATION.map(item => (
                <Link
                  className="relative bg-base-200 hover:scale-105 transition-all duration-300 text-2xl p-8 rounded-3xl shadow-lg"
                  key={item.href}
                  href={item.href}
                  passHref
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  <h3 className="text-3xl font-bold mb-5">{item.title}</h3>
                  <p className="text-xl mb-0">{item.description}</p>
                </Link>
              ))}
            </div>
          </div>

          <div className="w-full">
            <h3 className="text-start text-3xl font-bold mb-7">Videos</h3>
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-10">
              {VIDEOS.map(item => (
                <Link
                  className="relative bg-base-200 hover:scale-105 transition-all duration-300 text-2xl text-center p-5 rounded-3xl shadow-lg"
                  key={item.href}
                  href={item.href}
                  passHref
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  <div className="aspect-video">
                    {/* eslint-disable-next-line */}
                    <img
                      src={`https://img.youtube.com/vi/${item.href.split("v=")[1]}/maxresdefault.jpg`}
                      alt={item.title}
                      className="w-full h-full object-cover rounded-xl"
                    />
                  </div>
                </Link>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Home;
