import { useState } from "react";
import { type Address, isAddress } from "viem";
import { ChevronDownIcon, MagnifyingGlassIcon } from "@heroicons/react/24/outline";

/**
 * The dropdown selector for internal custom pool and the external pool address input
 */
export const PoolSelector = ({
  scaffoldPools,
  setSelectedPoolAddress,
}: {
  scaffoldPools: any;
  setSelectedPoolAddress: (_: Address | undefined) => void;
}) => {
  const [inputValue, setInputValue] = useState<string>("");
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);

  const isValidAddress = isAddress(inputValue);
  return (
    <section className="flex justify-center flex-wrap gap-5 w-full mb-5 items-center text-xl py-5 border-b border-t border-base-100">
      <div className={`dropdown dropdown-end ${isDropdownOpen ? "dropdown-open" : ""}`}>
        <div
          tabIndex={0}
          role="button"
          className="btn text-lg btn-accent w-96 font-normal relative"
          onClick={() => setIsDropdownOpen(!isDropdownOpen)}
        >
          <div>Your scaffold pools</div> <ChevronDownIcon className="absolute top-4 right-5 w-5 h-5" />
        </div>
        <ul
          tabIndex={0}
          className={`dropdown-content z-[1] menu p-2 shadow bg-base-100 rounded-box w-52 mt-3 ${
            !isDropdownOpen ? "hidden" : ""
          }`}
        >
          {scaffoldPools.map((pool: any) => (
            <li key={pool.name}>
              <button
                onClick={() => {
                  setSelectedPoolAddress(pool.address);
                  setIsDropdownOpen(false); // Close the dropdown
                }}
              >
                {pool.name}
              </button>
            </li>
          ))}
        </ul>
      </div>
      <div>OR</div>
      <form
        className="flex flex-row items-center gap-2"
        onSubmit={event => {
          event.preventDefault();
          setSelectedPoolAddress(inputValue);
          setInputValue("");
        }}
      >
        <div className="relative">
          <input
            value={inputValue}
            onChange={e => setInputValue(e.target.value)}
            className="input input-bordered bg-base-200 w-96 text-center pr-16"
            placeholder="Search by contract addresss"
          />
          <button className="btn btn-sm btn-accent absolute top-2 right-3 " type="submit" disabled={!isValidAddress}>
            <MagnifyingGlassIcon className="h-5 w-5" />
          </button>
        </div>
      </form>
    </section>
  );
};
