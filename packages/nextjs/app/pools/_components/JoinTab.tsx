import React, { useState } from "react";
import { InputAmount } from "@balancer/sdk";
import { parseUnits } from "viem";
import { useJoin } from "~~/hooks/balancer/";
import { type Pool } from "~~/hooks/balancer/types";

/**
 *
 */
export const JoinTab = ({ pool }: { pool: Pool }) => {
  const { queryJoin } = useJoin();
  // Initialize state with each token's address, decimals, and amount (the proper shape for balancer sdk)
  const [tokenInputs, setTokenInputs] = useState(
    pool.poolTokens.map(token => ({
      address: token.address as `0x${string}`,
      decimals: token.decimals,
      humanReadableAmount: "",
    })),
  );

  const handleInputChange = (index: number, value: string) => {
    const updatedTokens = tokenInputs.map((input, idx) => {
      if (idx === index) {
        return { ...input, humanReadableAmount: value };
      }
      return input;
    });
    setTokenInputs(updatedTokens);
  };

  const handleQueryJoin = async () => {
    const amountsIn: InputAmount[] = tokenInputs.map(token => ({
      ...token,
      // format the human-readable amount to the raw amount for balancer sdk
      rawAmount: parseUnits(token.humanReadableAmount, token.decimals as number) || 0n,
    }));

    await queryJoin(pool.address as string, amountsIn);
  };

  return (
    <section>
      <div className="mb-5">
        <div>
          <label>Tokens In</label>
        </div>
        {tokenInputs.map((token, index) => (
          <div key={token.address} className="relative mb-5">
            <input
              value={token.humanReadableAmount}
              onChange={e => handleInputChange(index, e.target.value)}
              type="number"
              placeholder="0.0"
              className="text-2xl w-full input input-bordered rounded-lg bg-base-200 p-10"
            />
            <div className="dropdown dropdown-end absolute top-3 right-4 ">
              <div className="btn m-1 btn-accent rounded-lg w-24">{pool.poolTokens[index].symbol}</div>
            </div>
          </div>
        ))}
      </div>
      <div>
        <button onClick={handleQueryJoin} className="btn btn-accent mt-3 w-full rounded-lg">
          Query Join
        </button>
      </div>
    </section>
  );
};
