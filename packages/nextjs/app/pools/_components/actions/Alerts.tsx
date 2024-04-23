import { ArrowTopRightOnSquareIcon } from "@heroicons/react/24/outline";

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
      <h5 className="mt-5 mb-1 ml-2">{title}</h5>
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

/**
 * Displays after successful pool operation transaction
 */
export const ActionSuccessAlert: React.FC<{ transactionUrl: string }> = ({ transactionUrl }) => {
  return (
    <div className="bg-[#43fb522b] border border-green-600 rounded-lg p-5 mt-3">
      <div className="flex flex-wrap justify-between">
        <div className="font-bold">Transaction Success 🎉</div>
        <a
          rel="noopener"
          target="_blank"
          href={transactionUrl}
          className="text-neutral underline flex items-center gap-1"
        >
          block explorer <ArrowTopRightOnSquareIcon className="w-4 h-4" />
        </a>
      </div>
    </div>
  );
};
