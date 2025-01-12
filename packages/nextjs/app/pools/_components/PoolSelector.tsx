import { Dispatch, SetStateAction, useState } from "react";
import { usePathname, useRouter } from "next/navigation";
import { blo } from "blo";
import { type Address, isAddress } from "viem";
import { MagnifyingGlassIcon } from "@heroicons/react/24/outline";
import { useFactoryHistory } from "~~/hooks/balancer";

type PoolSelectorProps = {
  setSelectedPoolAddress: Dispatch<SetStateAction<string | null>>;
  selectedPoolAddress: Address | null;
};

export const PoolSelector = ({ setSelectedPoolAddress, selectedPoolAddress }: PoolSelectorProps) => {
  const [inputValue, setInputValue] = useState<string>("");

  const { sumPools, productPools, weightedPools } = useFactoryHistory();

  const poolTypes = [
    { label: "Constant Sum", addresses: sumPools },
    { label: "Constant Product", addresses: productPools },
    { label: "Weighted", addresses: weightedPools },
  ];

  return (
    <section className="mb-7">
      <SearchBar
        inputValue={inputValue}
        setInputValue={setInputValue}
        setSelectedPoolAddress={setSelectedPoolAddress}
      />
      <div className="flex flex-wrap justify-center gap-3 mt-4">
        {poolTypes.map(
          ({ label, addresses }) =>
            addresses.length > 0 &&
            addresses.map(address => (
              <PoolSelectButton
                key={address}
                label={label}
                address={address}
                setInputValue={setInputValue}
                selectedPoolAddress={selectedPoolAddress}
                setSelectedPoolAddress={setSelectedPoolAddress}
              />
            )),
        )}
      </div>
    </section>
  );
};

type SearchBarProps = {
  setSelectedPoolAddress: (_: Address) => void;
  inputValue: string;
  setInputValue: Dispatch<SetStateAction<string>>;
};

const SearchBar = ({ setSelectedPoolAddress, inputValue, setInputValue }: SearchBarProps) => {
  const router = useRouter();
  const pathname = usePathname();
  const isValidAddress = isAddress(inputValue);

  return (
    <div className="flex justify-center flex-wrap gap-5 w-full items-center text-xl">
      <form
        className="flex flex-wrap items-center gap-5"
        onSubmit={event => {
          event.preventDefault();
          setSelectedPoolAddress(inputValue);
          router.push(`${pathname}?address=${inputValue}`);
          setInputValue("");
        }}
      >
        <div className="relative">
          {inputValue && (
            // eslint-disable-next-line @next/next/no-img-element
            <img
              alt=""
              className="!rounded-full absolute top-1 left-1"
              src={blo(inputValue as `0x${string}`)}
              width="37"
              height="37"
            />
          )}
          <input
            value={inputValue}
            onChange={e => setInputValue(e.target.value)}
            className={`input input-bordered bg-base-200 text-center h-[44px] w-[355px] sm:w-[550px] ${
              inputValue && "pl-10 pr-14"
            }`}
            placeholder="Search by pool addresss"
          />
          <button
            className={`btn btn-sm bg-neutral w-12 absolute top-1.5 right-1.5 border-none ${
              isValidAddress ? "bg-violet-400 hover:bg-violet-400" : ""
            }`}
            type="submit"
            disabled={!isValidAddress}
          >
            <MagnifyingGlassIcon className="h-5 w-5" />
          </button>
        </div>
      </form>
    </div>
  );
};

type PoolSelectButtonProps = PoolSelectorProps & {
  address: Address;
  label: string;
  setInputValue: Dispatch<SetStateAction<string>>;
};

const PoolSelectButton = ({
  selectedPoolAddress,
  setSelectedPoolAddress,
  address,
  label,
  setInputValue,
}: PoolSelectButtonProps) => {
  const router = useRouter();
  const pathname = usePathname();

  return (
    <button
      key={address}
      className={`btn btn-sm btn-secondary flex relative pl-[35px] border-none font-normal text-lg ${
        selectedPoolAddress === address
          ? " text-neutral-700 bg-gradient-to-b from-custom-beige-start to-custom-beige-end to-100%"
          : ""
      }`}
      onClick={() => {
        setSelectedPoolAddress(address);
        setInputValue(address);
        router.push(`${pathname}?address=${address}`);
      }}
    >
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img
        alt=""
        className={`!rounded-full absolute top-0.5 left-1 `}
        src={blo(address as `0x${string}`)}
        width="25"
        height="25"
      />
      {label}
    </button>
  );
};
