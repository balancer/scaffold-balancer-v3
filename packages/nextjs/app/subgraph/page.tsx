import type { NextPage } from "next";

// https://api.studio.thegraph.com/proxy/31386/balancer-v3-sepolia/version/latest/graphql?q[…]+%7B%0A++++++++id%0A++++++%7D%0A++++%7D%0A%09%7D%0A%7D%0A

const Subgraph: NextPage = () => {
  return (
    <>
      <div className="flex items-center flex-col flex-grow py-10 px-5 md:px-10 xl:px-20">
        <div className="mb-10">
          <h1 className="text-3xl md:text-5xl font-bold my-10">📡 Subgraph</h1>
          <p className="text-xl">
            Lorem ipsum dolor sit, amet consectetur adipisicing elit. Eveniet nemo praesentium molestias impedit
            mollitia quisquam fugit nobis possimus quis enim omnis similique repudiandae odit nihil deleniti harum
            tempora, quod exercitationem?
          </p>
        </div>
      </div>
    </>
  );
};

export default Subgraph;
