import { ArrowTopRightOnSquareIcon } from "@heroicons/react/24/outline";

// Define the props interface for easier type checking and autocomplete
interface PoolFeedbackProps {
  title: string; // The title of the query result section
  children: React.ReactNode; // The dynamic content passed to the component
}

export const PoolFeedback: React.FC<PoolFeedbackProps> = ({ title, children }) => {
  return (
    <div>
      <h5 className="mt-5 mb-1 ml-2">{title}</h5>
      <div className="bg-[#FCD34D40] border border-amber-400 rounded-lg p-5">{children}</div>
    </div>
  );
};

interface SuccessAlertProps {
  transactionUrl: string;
}

export const SuccessAlert: React.FC<SuccessAlertProps> = ({ transactionUrl }) => {
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
