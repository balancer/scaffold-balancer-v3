import { Fragment } from "react";
import {
  // useEffect,
  useState,
} from "react";
// import { ChainId, Slippage, Swap, SwapBuildOutputExactIn, SwapKind } from "@balancer/sdk";
// import { Address } from "viem";
// import { usePublicClient } from "wagmi";
import { ChevronDownIcon } from "@heroicons/react/24/outline";
import { type Pool } from "~~/hooks/balancer/types";

// import scaffoldConfig from "~~/scaffold.config";

/**
 * Allow user to perform swap transactions within the given pool
 */
export const SwapTab = ({ pool }: { pool: Pool }) => {
  console.log("pool", pool);

  const [swapConfig, setSwapConfig] = useState({
    tokenIn: {
      amount: "",
      symbol: pool.poolTokens[0].symbol,
    },
    tokenOut: {
      amount: "",
      symbol: pool.poolTokens[1].symbol,
    },
  });

  const [isTokenInDropdownOpen, setTokenInDropdownOpen] = useState(false);
  const [isTokenOutDropdownOpen, setTokenOutDropdownOpen] = useState(false);

  //   const client = usePublicClient();
  //   const RPC_URL = client.chain.rpcUrls.default.http[0];

  //   // User defined
  //   const chainId = scaffoldConfig.targetNetworks[0].id;
  //   const swapKind = SwapKind.GivenIn;

  //   // User defined
  //   const swapInput = {
  //     chainId: ChainId.SEPOLIA,
  //     swapKind: SwapKind.GivenIn,
  //     paths: [
  //       {
  //         pools: [pool.address as Address],
  //         tokens: [
  //           {
  //             address: "0xb19382073c7a0addbb56ac6af1808fa49e377b75" as Address,
  //             decimals: 18,
  //           }, // tokenIn
  //           {
  //             address: "0xf04378a3ff97b3f979a46f91f9b2d5a1d2394773" as Address,
  //             decimals: 18,
  //           }, // tokenOut
  //         ],
  //         vaultVersion: 3 as const,
  //         inputAmountRaw: 1000000000000000000n,
  //         outputAmountRaw: 990000000000000000n,
  //       },
  //     ],
  //   };

  //   const swap = new Swap(swapInput);

  //   useEffect(() => {
  //     async function querySwap() {
  //       const updatedOutputAmount = await swap.query(RPC_URL);

  //       console.log("updatedOutputAmount", updatedOutputAmount);
  //     }
  //     querySwap();
  //   }, [chainId, swap, swapKind, swapInput, RPC_URL]);

  const handleTokenAmountChange = (amount: string, tokenType: any) => {
    setSwapConfig(prevConfig => ({
      ...prevConfig,
      [tokenType]: {
        ...prevConfig[tokenType as keyof typeof swapConfig],
        amount,
      },
    }));
  };

  // Function to handle the selection of a new token
  const handleTokenSelection = (symbol: string, tokenType: string) => {
    setSwapConfig(prevConfig => ({
      ...prevConfig,
      [tokenType]: {
        ...prevConfig[tokenType as keyof typeof swapConfig],
        symbol,
      },
    }));
    // Close the dropdowns
    setTokenInDropdownOpen(false);
    setTokenOutDropdownOpen(false);
  };

  return (
    <Fragment>
      <div className="mb-5">
        <div>
          <label>Token In</label>
        </div>
        <div className="relative">
          <input
            type="number"
            value={swapConfig.tokenIn.amount}
            onChange={e => handleTokenAmountChange(e.target.value, "tokenIn")}
            placeholder="0.0"
            className="text-2xl w-full input input-bordered rounded-lg bg-base-200 p-10"
          />
          <div className="dropdown dropdown-end absolute top-3 right-4 ">
            <div
              onClick={() => setTokenInDropdownOpen(!isTokenInDropdownOpen)}
              tabIndex={0}
              role="button"
              className="btn m-1 btn-accent rounded-lg w-24"
            >
              {swapConfig.tokenIn.symbol} <ChevronDownIcon className="w-4 h-4" />
            </div>
            <ul
              tabIndex={0}
              className={`dropdown-content z-[1] menu p-2 shadow bg-base-100 rounded-box w-52 ${
                !isTokenInDropdownOpen ? "hidden" : ""
              }`}
            >
              {pool.poolTokens
                .filter(token => token.symbol !== swapConfig.tokenIn.symbol)
                .map(token => (
                  <li key={token.symbol} onClick={() => handleTokenSelection(token.symbol, "tokenIn")}>
                    <a>{token.symbol}</a>
                  </li>
                ))}
            </ul>
          </div>
        </div>
      </div>
      <div className="mb-5">
        <div>
          <label>Token Out</label>
        </div>
        <div className="relative">
          <input
            type="number"
            value={swapConfig.tokenOut.amount}
            onChange={e => handleTokenAmountChange(e.target.value, "tokenOut")}
            placeholder="0.0"
            className="text-2xl w-full input input-bordered rounded-lg bg-base-200 p-10"
          />
          <div className="dropdown dropdown-end absolute top-3 right-4 ">
            <div
              onClick={() => setTokenOutDropdownOpen(!isTokenOutDropdownOpen)}
              tabIndex={0}
              role="button"
              className="btn m-1 btn-accent rounded-lg w-24"
            >
              {swapConfig.tokenOut.symbol} <ChevronDownIcon className="w-4 h-4" />
            </div>
            <ul
              tabIndex={0}
              className={`dropdown-content z-[1] menu p-2 shadow bg-base-100 rounded-box w-52 ${
                !isTokenOutDropdownOpen ? "hidden" : ""
              }`}
            >
              {pool.poolTokens
                .filter(token => token.symbol !== swapConfig.tokenOut.symbol)
                .map(token => (
                  <li key={token.symbol} onClick={() => handleTokenSelection(token.symbol, "tokenOut")}>
                    <a>{token.symbol}</a>
                  </li>
                ))}
            </ul>
          </div>
        </div>
      </div>
      <div>
        <button className="btn btn-accent mt-3 w-full rounded-lg">Query Swap</button>
      </div>
    </Fragment>
  );
};
