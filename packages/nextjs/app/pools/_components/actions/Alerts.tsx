import { usePublicClient } from "wagmi";
import { ArrowTopRightOnSquareIcon } from "@heroicons/react/24/outline";
import { type TokenInfo } from "~~/hooks/balancer/types";
import { formatToHuman } from "~~/utils/formatToHuman";
import { getBlockExplorerTxLink } from "~~/utils/scaffold-eth";

interface QueryResponseAlertProps {
  title: string;
  data: queryData[];
}

type queryData = {
  type: string;
  description?: string;
  rawAmount: bigint;
  decimals: number;
};

/**
 * Displays results after successful query (just a style wrapper for query result info)
 */
export const QueryResponseAlert: React.FC<QueryResponseAlertProps> = ({ title, data }) => {
  return (
    <div className="">
      <h5 className="mt-5 mb-1 ml-2">{title}</h5>
      <div className="bg-warning-tint text-warning border border-warning rounded-lg p-5">
        {data &&
          data.map((item, idx) => (
            <div key={idx} className={`flex justify-between ${idx !== data.length - 1 ? "mb-3" : ""}`}>
              <div>
                <div className="font-bold">{item.type}</div>
                <div className="text-sm">{item.description}</div>
              </div>
              <div className="text-end">
                <div className="font-bold">{formatToHuman(item.rawAmount, item.decimals)}</div>
                <div className="text-sm">{item.rawAmount.toString()}</div>
              </div>
            </div>
          ))}
      </div>
    </div>
  );
};

/**
 * Displays if query thdatas an error
 */
export const QueryErrorAlert: React.FC<{ message: string }> = ({ message }) => {
  return (
    <div className="mt-3">
      <div className="ml-2 mb-1">Error</div>
      <div className="bg-error-tint border border-error rounded-lg p-5 overflow-auto text-error">
        <div>{message}</div>
      </div>
    </div>
  );
};

interface TransactionReceiptAlertProps {
  transactionHash: string;
  title: string;
  data: TokenInfo[];
}
/**
 * Displays after successful pool operation transaction
 */
export const TransactionReceiptAlert: React.FC<TransactionReceiptAlertProps> = ({ title, transactionHash, data }) => {
  const publicClient = usePublicClient();
  const chainId = publicClient?.chain.id as number;
  const transactionUrl = getBlockExplorerTxLink(chainId, transactionHash);

  return (
    <div className="mt-5">
      <div className="flex justify-between items-center mb-1">
        <div className="ml-2">{title}</div>
        {chainId !== 31337 && (
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

      <div className="bg-success-tint border border-success text-success rounded-lg p-5">
        {data &&
          data.map((token, idx) => (
            <div key={idx} className={`flex justify-between ${idx !== data.length - 1 ? "mb-3" : ""}`}>
              <div>
                <div className="font-bold">{token.symbol}</div>
                <div className="text-sm">{token.name}</div>
              </div>
              <div className="text-end">
                <div className="font-bold">{formatToHuman(token.rawAmount, token.decimals)}</div>
                <div className="text-sm">{token.rawAmount.toString()}</div>
              </div>
            </div>
          ))}
      </div>
    </div>
  );
};
