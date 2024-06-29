import React from "react";

interface PoolActionButtonProps {
  onClick: () => void;
  children: React.ReactNode;
  className?: string;
  isDisabled?: boolean;
  isFormEmpty?: boolean;
}

/**
 * Approve button is outlined style
 * Swap, AddLiquidity, and RemoveLiquidity buttons are solid gradient style
 */
export const PoolActionButton: React.FC<PoolActionButtonProps> = ({ onClick, children, isDisabled, isFormEmpty }) => {
  const outlined = `border border-neutral hover:bg-neutral hover:text-neutral-content`;
  const gradient = `bg-gradient-to-r from-violet-400 via-orange-100 to-orange-300 hover:from-violet-300 hover:via-orange-100 hover:to-orange-400 text-neutral-700 `;

  const colorStyles = children === "Approve" ? outlined : isFormEmpty ? `bg-[#334155] opacity-70 text-white` : gradient;
  const baseStyles = `w-full rounded-lg font-bold py-4 `;

  return (
    <button onClick={onClick} className={baseStyles + colorStyles} disabled={isDisabled || isFormEmpty}>
      {!isFormEmpty && isDisabled ? <span className="loading loading-bars loading-sm"></span> : children}
    </button>
  );
};
