import { useEffect, useState } from "react";
import { usePathname, useRouter } from "next/navigation";
import { blo } from "blo";
import { type Address, isAddress } from "viem";
import { ChevronDoubleDownIcon, MagnifyingGlassIcon } from "@heroicons/react/24/outline";
import { useScaffoldEventHistory, useScaffoldEventSubscriber } from "~~/hooks/scaffold-eth";

/**
 * The dropdown selector for internal custom pool and the external pool address input
 */
export const PoolSelector = ({ setSelectedPoolAddress }: { setSelectedPoolAddress: (_: Address) => void }) => {
  const [inputValue, setInputValue] = useState<string>("");
  const [isOpen, setIsOpen] = useState<boolean>(false);
  const [createdPools, setCreatedPools] = useState<any[]>([]);

  const router = useRouter();
  const pathname = usePathname();
  const isValidAddress = isAddress(inputValue);

  // Fetches the history of pools deployed using the factory
  const { data: eventsHistory, isLoading: isLoadingEventsHistory } = useScaffoldEventHistory({
    contractName: "CustomPoolFactoryExample",
    eventName: "PoolCreated",
    fromBlock: 5837241n,
  });

  // Adds pools deployed using the factory to the dropdown
  useScaffoldEventSubscriber({
    contractName: "CustomPoolFactoryExample",
    eventName: "PoolCreated",
    listener: logs => {
      logs.forEach(log => {
        console.log("PoolCreated Event!", log);
        const { pool } = log.args;
        setCreatedPools(pools => [...pools, pool]);
      });
    },
  });

  useEffect(() => {
    if (!createdPools?.length && !!eventsHistory?.length && !isLoadingEventsHistory) {
      setCreatedPools(
        eventsHistory.map(({ args }) => {
          return args.pool;
        }) || [],
      );
    }
  }, [createdPools.length, eventsHistory, isLoadingEventsHistory]);

  return (
    <section className="flex justify-center flex-wrap gap-5 w-full items-center text-xl my-10">
      <form
        className="flex flex-wrap items-center gap-3"
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
              width="45"
              height="45"
            />
          )}
          <input
            value={inputValue}
            onChange={e => setInputValue(e.target.value)}
            className={`input input-bordered bg-base-200 text-center h-[52px] w-[355px] sm:w-[550px] ${
              inputValue && "pl-10 pr-14"
            }`}
            placeholder="Search by pool addresss"
          />
          <button
            className={`btn w-16 absolute top-0.5 right-0.5 text-white ${
              isValidAddress
                ? "bg-gradient-to-tr from-indigo-700 from-15% to-fuchsia-600 hover:from-indigo-700 hover:to-fuchsia-700"
                : ""
            }`}
            type="submit"
            disabled={!isValidAddress}
          >
            <MagnifyingGlassIcon className="h-5 w-5" />
          </button>
        </div>

        {createdPools.length > 0 && (
          <div className="dropdown dropdown-end">
            <div
              onClick={() => setIsOpen(!isOpen)}
              tabIndex={0}
              role="button"
              className={`btn w-16 bg-base-100 hover:bg-accent`}
            >
              <ChevronDoubleDownIcon className="h-5 w-5" />
            </div>
            {isOpen && (
              <ul
                tabIndex={0}
                className="dropdown-content z-[1] menu p-4 shadow bg-base-200 rounded-box w-[633px] mt-3 border border-base-100"
              >
                {createdPools && (
                  <>
                    {createdPools.map((poolAddress: string, idx: number) => {
                      return (
                        <li
                          key={idx}
                          onClick={() => {
                            setSelectedPoolAddress(poolAddress);
                            router.push(`${pathname}?address=${poolAddress}`);
                            setIsOpen(false);
                          }}
                          className="cursor-pointer text-xl "
                        >
                          <div className="flex gap-5">
                            {/* eslint-disable-next-line @next/next/no-img-element */}
                            <img
                              alt=""
                              className="!rounded-full"
                              src={blo(poolAddress as `0x${string}`)}
                              width="35"
                              height="35"
                            />
                            <div>{poolAddress}</div>
                          </div>
                        </li>
                      );
                    })}
                  </>
                )}
              </ul>
            )}
          </div>
        )}
      </form>
    </section>
  );
};
