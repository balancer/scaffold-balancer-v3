import { ArrowTopRightOnSquareIcon } from "@heroicons/react/24/outline";

interface SuccessNotificationProps {
  transactionUrl: string;
}

export const SuccessNotification: React.FC<SuccessNotificationProps> = ({ transactionUrl }) => {
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
