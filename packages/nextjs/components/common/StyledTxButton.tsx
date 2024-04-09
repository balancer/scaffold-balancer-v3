import React from "react";

interface StyledTxButtonProps {
  onClick: () => void;
  children: React.ReactNode;
  className?: string;
  isDisabled?: boolean;
}

/**
 * Styled button for approve and join/swap/exit transactions
 *
 * Approve button is outlined styles
 * Join/Swap/Exit buttons are solid styles
 */
export const StyledTxButton: React.FC<StyledTxButtonProps> = ({ onClick, children, isDisabled }) => {
  const outlinedStyles = `border border-neutral hover:bg-neutral hover:text-neutral-content font-bold w-full py-4 rounded-lg`;
  const solidStyles = `bg-neutral hover:bg-neutral-200 text-neutral-content font-bold w-full py-4 rounded-lg`;

  const processingStyles = `bg-neutral-300 py-3 w-full rounded-lg`;

  const classNames = children === "Approve" ? outlinedStyles : solidStyles;
  return (
    <button onClick={onClick} className={isDisabled ? processingStyles : classNames} disabled={isDisabled}>
      {isDisabled ? <span className="loading loading-bars loading-md text-neutral-600"></span> : children}
    </button>
  );
};
