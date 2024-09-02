import React from "react";

interface PoolActionButtonProps {
  onClick: () => void;
  label: string;
  className?: string;
  isDisabled?: boolean;
  isFormEmpty?: boolean;
}

/**
 * Approve button is outlined style
 * Swap, AddLiquidity, and RemoveLiquidity buttons are solid gradient style
 */
export const TransactionButton: React.FC<PoolActionButtonProps> = ({ onClick, label, isDisabled, isFormEmpty }) => {
  const outlined = `border border-base-100 hover:bg-base-100`;
  const gradient = `shadow-md bg-gradient-to-r from-violet-400 via-orange-100 to-orange-300 hover:from-violet-300 hover:via-orange-100 hover:to-orange-400 text-neutral-700 `;

  const colorStyles = label === "Approve" ? outlined : isFormEmpty ? `bg-neutral-400 opacity-70 text-white` : gradient;
  const baseStyles = `w-full rounded-lg font-bold py-4 `;

  return (
    <button onClick={onClick} className={baseStyles + colorStyles} disabled={isDisabled || isFormEmpty}>
      {!isFormEmpty && isDisabled ? <span className="loading loading-bars loading-sm"></span> : label}
    </button>
  );
};
