import { Dispatch, SetStateAction, useEffect, useState } from "react";
import Image from "next/image";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { blo } from "blo";
import { type Address, isAddress } from "viem";
import { MagnifyingGlassIcon } from "@heroicons/react/24/outline";
import { useFactoryHistory } from "~~/hooks/balancer";
import { useReadPool } from "~~/hooks/balancer/useReadPool";

type PoolSelectorProps = {
  setSelectedPoolAddress: Dispatch<SetStateAction<string | null>>;
  selectedPoolAddress: Address | null;
};

export const PoolSelector = ({ setSelectedPoolAddress, selectedPoolAddress }: PoolSelectorProps) => {
  const router = useRouter();
  const pathname = usePathname();
  const [inputValue, setInputValue] = useState<string>("");
  const [selectedType, setSelectedType] = useState<string | null>(null);
  const searchParams = useSearchParams();

  const { sumPools, productPools, weightedPools, isLoading } = useFactoryHistory();

  // Clear selected pool when there's no address in the URL
  useEffect(() => {
    const addressParam = searchParams.get("address");
    if (!addressParam) {
      setSelectedPoolAddress(null);
      setSelectedType(null);
      setInputValue("");
    }
  }, [searchParams, setSelectedPoolAddress]);

  const poolTypes = [
    { label: "Constant Sum", addresses: sumPools as Address[] },
    { label: "Constant Product", addresses: productPools as Address[] },
    { label: "Weighted", addresses: weightedPools as Address[] },
  ];

  return (
    <section className="mb-7">
      <SearchBar
        inputValue={inputValue}
        setInputValue={setInputValue}
        setSelectedPoolAddress={setSelectedPoolAddress}
      />
      <div className="flex flex-wrap justify-center gap-3 mt-4">
        {isLoading ? (
          <div>Loading pools...</div>
        ) : (
          <>
            {/* Pool Type Selection */}
            {!selectedType &&
              poolTypes.map(({ label, addresses }) => (
                <button key={label} className="btn btn-lg btn-secondary" onClick={() => setSelectedType(label)}>
                  {label} ({addresses?.length || 0})
                </button>
              ))}

            {/* Pool Instance Selection */}
            {selectedType && (
              <div className="w-full">
                <div className="flex justify-between items-center mb-4">
                  <h3 className="text-xl font-bold">{selectedType} Pools</h3>
                  <button
                    className="btn btn-sm btn-ghost"
                    onClick={() => {
                      setSelectedType(null);
                      setSelectedPoolAddress(null);
                      setInputValue("");
                      router.push(pathname); // Remove URL parameters
                    }}
                  >
                    ← Back to Pool Types
                  </button>
                </div>
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                  {poolTypes
                    .find(type => type.label === selectedType)
                    ?.addresses?.map(address => (
                      <PoolSelectCard
                        key={address}
                        address={address}
                        setInputValue={setInputValue}
                        selectedPoolAddress={selectedPoolAddress}
                        setSelectedPoolAddress={setSelectedPoolAddress}
                      />
                    ))}
                </div>
              </div>
            )}
          </>
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
            <Image
              alt="Pool identicon"
              className="!rounded-full absolute top-1 left-1"
              src={blo(inputValue as `0x${string}`)}
              width={37}
              height={37}
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

type PoolSelectCardProps = {
  address: Address;
  selectedPoolAddress: Address | null;
  setSelectedPoolAddress: (_: Address) => void;
  setInputValue: Dispatch<SetStateAction<string>>;
};

const PoolSelectCard = ({
  address,
  selectedPoolAddress,
  setSelectedPoolAddress,
  setInputValue,
}: PoolSelectCardProps) => {
  const router = useRouter();
  const pathname = usePathname();
  const { data: pool } = useReadPool(address);

  if (!pool) return null;

  const tokenNames = pool.poolTokens.map(token => token.symbol).join(" / ");

  return (
    <button
      className={`card bg-base-200 shadow-xl hover:shadow-2xl transition-all ${
        selectedPoolAddress === address ? "border-2 border-accent" : ""
      }`}
      onClick={() => {
        setSelectedPoolAddress(address);
        setInputValue(address);
        router.push(`${pathname}?address=${address}`);
      }}
    >
      <div className="card-body">
        <div className="flex items-center gap-2">
          <Image
            alt="Pool identicon"
            className="rounded-full"
            src={blo(address as `0x${string}`)}
            width={40}
            height={40}
          />
          <div className="text-left">
            <h3 className="card-title">{tokenNames}</h3>
            <p className="text-sm opacity-70">{address}</p>
          </div>
        </div>
      </div>
    </button>
  );
};
