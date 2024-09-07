import { usePublicClient } from "wagmi";
import { ArrowTopRightOnSquareIcon } from "@heroicons/react/24/outline";
import { TokenAmountDisplay } from "~~/components/common";
import { type TokenAmountDetails } from "~~/hooks/balancer/types";
import { getBlockExplorerTxLink } from "~~/utils/scaffold-eth";

interface ResultsDisplay {
  label: string;
  data: TokenAmountDetails[];
  transactionHash?: string;
}
/**
 * Displays after successful pool operation transaction
 */
export const ResultsDisplay: React.FC<ResultsDisplay> = ({ label, transactionHash, data }) => {
  const publicClient = usePublicClient();
  const chainId = publicClient?.chain.id as number;

  const transactionUrl = getBlockExplorerTxLink(chainId, transactionHash ?? "");

  const styles = transactionHash ? "bg-success" : "bg-warning";

  return (
    <div>
      <div className="flex justify-between items-center mb-1">
        <div className="ml-2 font-bold">{label}</div>
        {chainId !== 31337 && transactionUrl && (
          <a
            rel="noopener"
            target="_blank"
            href={transactionUrl}
            className="text-blue-500 underline flex items-center gap-1"
          >
            block explorer <ArrowTopRightOnSquareIcon className="w-4 h-4" />
          </a>
        )}
      </div>

      <div className={`${styles} text-neutral-800 rounded-lg p-4 flex flex-col gap-3`}>
        {data.map((item, idx) => (
          <TokenAmountDisplay
            key={idx}
            symbol={item.symbol}
            name={item.name}
            decimals={item.decimals}
            rawAmount={item.rawAmount}
          />
        ))}
      </div>
    </div>
  );
};
