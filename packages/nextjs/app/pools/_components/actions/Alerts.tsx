import { usePublicClient } from "wagmi";
import { ArrowTopRightOnSquareIcon } from "@heroicons/react/24/outline";
import { formatToHuman } from "~~/utils/formatToHuman";
import { getBlockExplorerTxLink } from "~~/utils/scaffold-eth";

interface QueryResultsWrapperProps {
  title: string;
  children: React.ReactNode;
}
/**
 * Displays results after successful query (just a style wrapper for query result info)
 */
export const QueryResultsWrapper: React.FC<QueryResultsWrapperProps> = ({ title, children }) => {
  return (
    <div>
      <h5 className="mt-5 mb-1 ml-2">Query {title}</h5>
      <div className="bg-[#FCD34D40] border border-amber-400 rounded-lg p-5">{children}</div>
    </div>
  );
};

/**
 * Displays if query throws an error
 */
export const QueryErrorAlert: React.FC<{ message: string }> = ({ message }) => {
  return (
    <div className="mt-3 text-red-500">
      <div className="ml-2 mb-1">Error</div>
      <div className="bg-[#f871712b] border border-red-700 rounded-lg p-5 overflow-auto">
        <div>{message}</div>
      </div>
    </div>
  );
};

interface ActionSuccessAlertProps {
  transactionHash: string;
  rows: row[];
}
type row = {
  title: string;
  rawAmount: bigint;
  decimals: number;
};
/**
 * Displays after successful pool operation transaction
 */
export const ActionSuccessAlert: React.FC<ActionSuccessAlertProps> = ({ transactionHash, rows }) => {
  const publicClient = usePublicClient();
  const chainId = publicClient?.chain.id as number;
  const transactionUrl = getBlockExplorerTxLink(chainId, transactionHash);

  return (
    <div className="mt-5">
      <div className="flex justify-between items-center mb-1">
        <div className="ml-2">Transaction Result</div>
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

      <div className="bg-[#43fb522b] border border-green-600 rounded-lg p-5">
        <div>
          {rows &&
            rows.map((row, idx) => (
              <div key={idx} className={`flex justify-between ${idx !== rows.length - 1 ? "mb-3" : ""}`}>
                <div className="font-bold">{row.title}</div>
                <div className="text-end">
                  <div className="font-bold">{formatToHuman(row.rawAmount, row.decimals)}</div>
                  <div className="text-sm">{row.rawAmount.toString()}</div>
                </div>
              </div>
            ))}
        </div>
      </div>
    </div>
  );
};
