import React from "react";

/**
 * Site footer
 */
export const Footer = () => {
  return (
    <div className="min-h-0 py-5 px-1 mb-11 lg:mb-0 bg-base-300 border-t border-1 border-base-200">
      <div className="w-full">
        <ul className="menu menu-horizontal w-full">
          <div className="flex justify-center items-center gap-5 text-xl w-full">
            <div className="text-center">
              <a
                href="https://github.com/balancer/scaffold-balancer-v3"
                target="_blank"
                rel="noreferrer"
                className="link no-underline hover:underline"
              >
                Github
              </a>
            </div>

            <span>·</span>
            <div className="text-center">
              <a
                href="https://github.com/balancer/balancer-v3-monorepo"
                target="_blank"
                rel="noreferrer"
                className="link no-underline hover:underline"
              >
                Contracts
              </a>
            </div>
            <span>·</span>
            <div className="text-center">
              <a
                href="https://docs.balancer.fi/build/"
                target="_blank"
                rel="noreferrer"
                className="link no-underline hover:underline"
              >
                Docs
              </a>
            </div>
          </div>
        </ul>
      </div>
    </div>
  );
};
