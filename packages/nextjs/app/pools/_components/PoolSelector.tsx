import { Dispatch, SetStateAction, useState } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { blo } from "blo";
import { type Address, isAddress } from "viem";
import { MagnifyingGlassIcon } from "@heroicons/react/24/outline";
import { Alert } from "~~/components/common";
import { useFactoryHistory } from "~~/hooks/balancer";
import { useTargetNetwork } from "~~/hooks/scaffold-eth/useTargetNetwork";

type PoolSelectorProps = {
  setSelectedPoolAddress: Dispatch<SetStateAction<string | null>>;
  selectedPoolAddress: Address | null;
};

export const PoolSelector = ({ setSelectedPoolAddress, selectedPoolAddress }: PoolSelectorProps) => {
  const [inputValue, setInputValue] = useState<string>("");

  const { sumPools, productPools, weightedPools } = useFactoryHistory();
  const { targetNetwork } = useTargetNetwork();
  const poolTypes = [
    { label: "Constant Sum", addresses: sumPools },
    { label: "Constant Product", addresses: productPools },
    { label: "Weighted", addresses: weightedPools },
  ];

  return (
    <section className="mb-7 flex flex-col items-center">
      <SearchBar
        inputValue={inputValue}
        setInputValue={setInputValue}
        setSelectedPoolAddress={setSelectedPoolAddress}
      />
      {/* Only show example pools on sepolia */}
      {targetNetwork.id === 11155111 ? (
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
      ) : (
        <div className="mt-7 flex justify-center w-[555px]">
          <Alert type="info">
            You are connected to the {targetNetwork.name} network. To find a v3 pool address, head to the{" "}
            <Link
              className="link"
              href={`https://balancer.fi/pools?protocolVersion=3&networks=${
                targetNetwork.name.toUpperCase() === "ETHEREUM" ? "MAINNET" : targetNetwork.name.toUpperCase()
              }`}
              target="_blank"
              rel="noopener noreferrer"
            >
              balancer.fi/pools.
            </Link>{" "}
            Alternatively, switch to Sepolia to interact with some example custom pools.
          </Alert>
        </div>
      )}
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
  const { targetNetwork } = useTargetNetwork();

  return (
    <div className="flex justify-center flex-wrap gap-5 w-full items-center text-xl">
      <form
        className="flex flex-wrap items-center gap-5"
        onSubmit={event => {
          event.preventDefault();
          setSelectedPoolAddress(inputValue);
          router.push(`${pathname}?address=${inputValue}&network=${targetNetwork.id}`);
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
  const { targetNetwork } = useTargetNetwork();
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
        router.push(`${pathname}?address=${address}&network=${targetNetwork.id}`);
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
