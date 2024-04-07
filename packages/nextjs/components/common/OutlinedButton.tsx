import React from "react";

interface OutlinedButtonProps {
  onClick: () => void;
  children: React.ReactNode;
  className?: string;
}

export const OutlinedButton: React.FC<OutlinedButtonProps> = ({ onClick, children }) => {
  return (
    <button
      onClick={onClick}
      className={`border border-neutral hover:bg-neutral hover:text-neutral-content font-bold w-full py-4 rounded-lg`}
    >
      {children}
    </button>
  );
};
