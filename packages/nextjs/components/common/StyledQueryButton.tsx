import React from "react";

interface StyledQueryButtonProps {
  isDisabled: boolean;
  onClick: () => void; // Assuming no event parameter is needed, adjust if necessary
  children: React.ReactNode; // Allows any valid React child (text, elements, fragments, etc.)
}

export const StyledQueryButton: React.FC<StyledQueryButtonProps> = ({ isDisabled, onClick, children }) => {
  return (
    <div>
      <button
        onClick={onClick}
        disabled={isDisabled}
        className={`w-full text-white font-bold py-4 rounded-lg ${
          isDisabled
            ? "bg-[#334155] opacity-70"
            : "bg-gradient-to-tr from-indigo-700 from-15% to-fuchsia-600 hover:from-indigo-700 hover:to-fuchsia-700"
        }`}
      >
        {children}
      </button>
    </div>
  );
};
