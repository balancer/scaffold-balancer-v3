import { useState } from "react";
import { TokenField } from "./TokenField";
import { TokenAmount } from "@balancer/sdk";
import { formatUnits, parseUnits } from "viem";
import { ArrowTopRightOnSquareIcon } from "@heroicons/react/24/outline";
import { GradientButton, OutlinedButton } from "~~/components/common";
import { useExit } from "~~/hooks/balancer/";
import { type Pool } from "~~/hooks/balancer/types";

type QueryResponse = {
  expectedAmountsOut: TokenAmount[] | undefined;
  minAmountsOut: TokenAmount[] | undefined;
};

/**
 *
 */
export const ExitTab = ({ pool }: { pool: Pool }) => {
  const [bptAmountIn, setBptAmountIn] = useState("");
  const [exitTxUrl, setExitTxUrl] = useState<string | undefined>();
  const [queryResponse, setQueryResponse] = useState<QueryResponse>({
    expectedAmountsOut: undefined,
    minAmountsOut: undefined,
  });

  const { userPoolBalance, queryExit, exitPool } = useExit(pool);

  const handleAmountChange = (amount: string) => {
    setBptAmountIn(amount);
    setQueryResponse({ expectedAmountsOut: undefined, minAmountsOut: undefined });
  };

  const handleExitQuery = async () => {
    const rawAmount = parseUnits(bptAmountIn, pool.decimals);
    const { expectedAmountsOut, minAmountsOut } = await queryExit(rawAmount);
    setQueryResponse({ expectedAmountsOut, minAmountsOut });
  };

  const handleExitPool = async () => {
    const txUrl = await exitPool();
    setExitTxUrl(txUrl);
  };

  return (
    <section>
      <TokenField
        label="BPT In"
        tokenSymbol={pool.symbol}
        value={bptAmountIn}
        onAmountChange={handleAmountChange}
        balance={Number(formatUnits(userPoolBalance || 0n, pool.decimals)).toFixed(4)}
      />
      <div className={`grid gap-5 ${queryResponse.expectedAmountsOut ? "grid-cols-2" : "grid-cols-1"}`}>
        <GradientButton onClick={handleExitQuery} isDisabled={bptAmountIn === ""}>
          Query Exit
        </GradientButton>
        {queryResponse.expectedAmountsOut && <OutlinedButton onClick={handleExitPool}>Exit Pool</OutlinedButton>}
      </div>

      {/* Query Result Display */}
      <h5 className="mt-5 mb-1 ml-2">Expected Tokens Out</h5>
      <div className="bg-[#FCD34D40] border border-amber-400 rounded-lg p-5">
        {pool.poolTokens.map((token, index) => (
          <div key={token.address} className={`${index === 0 ? "mb-3" : ""} flex justify-between items-center`}>
            <div>
              <div className="font-bold">{token.symbol}</div>
              <div className="text-sm">{token.name}</div>
            </div>
            <div>
              {queryResponse.expectedAmountsOut ? (
                <div>
                  <div className="font-bold text-end">{queryResponse.expectedAmountsOut[index].toSignificant(4)}</div>
                  <div className="text-sm">{queryResponse.expectedAmountsOut[index].amount.toString()}</div>
                </div>
              ) : (
                <div className="font-bold">0</div>
              )}
            </div>
          </div>
        ))}
        {exitTxUrl && (
          <div className="flex flex-wrap justify-between mt-5">
            <div className="font-bold">Actual Amounts Out</div>
            <a
              rel="noopener"
              target="_blank"
              href={exitTxUrl}
              className="text-neutral underline flex items-center gap-1"
            >
              block explorer <ArrowTopRightOnSquareIcon className="w-4 h-4" />
            </a>
          </div>
        )}
      </div>
    </section>
  );
};
