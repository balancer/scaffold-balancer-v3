import React from "react";

interface PoolActionButtonProps {
  onClick: () => void;
  children: React.ReactNode;
  className?: string;
  isDisabled?: boolean;
  isFormEmpty?: boolean;
}

/**
 * Styled button for approve and join/swap/exit transactions
 *
 * Approve button is outlined styles
 * Join/Swap/Exit buttons are solid styles
 */
export const PoolActionButton: React.FC<PoolActionButtonProps> = ({ onClick, children, isDisabled, isFormEmpty }) => {
  const approveBtnStyles = `border border-neutral hover:bg-neutral hover:text-neutral-content`;
  const solidStyles = `bg-gradient-to-tr from-indigo-700 from-15% to-fuchsia-600 hover:from-indigo-700 hover:to-fuchsia-700`;

  const colorStyles = children === "Approve" ? approveBtnStyles : isFormEmpty ? `bg-[#334155] opacity-70` : solidStyles;

  const baseStyles = `w-full rounded-lg font-bold py-4 `;
  return (
    <button onClick={onClick} className={baseStyles + colorStyles} disabled={isDisabled || isFormEmpty}>
      {!isFormEmpty && isDisabled ? <span className="loading loading-bars loading-sm"></span> : children}
    </button>
  );
};
