import { useEffect, useState } from "react";
import { usePathname, useRouter } from "next/navigation";
import { blo } from "blo";
import { type Address, isAddress } from "viem";
import { MagnifyingGlassIcon } from "@heroicons/react/24/outline";
import { useScaffoldEventHistory, useScaffoldEventSubscriber } from "~~/hooks/scaffold-eth";

// TODO: Figure out if this can be fetched from etherscan with contract address?
const FROM_BLOCK_NUMBER = 6278000n;

/**
 * The dropdown selector for internal custom pool and the external pool address input
 */
export const PoolSelector = ({
  setSelectedPoolAddress,
  selectedPoolAddress,
}: {
  setSelectedPoolAddress: (_: Address) => void;
  selectedPoolAddress: Address | null;
}) => {
  const [inputValue, setInputValue] = useState<string>("");
  const [createdPools, setCreatedPools] = useState<Address[]>([]);

  const router = useRouter();
  const pathname = usePathname();
  const isValidAddress = isAddress(inputValue);

  // Fetches the history of pools deployed via factory
  const { data: sumPoolHistory, isLoading: isLoadingSumPoolHistory } = useScaffoldEventHistory({
    contractName: "ConstantSumFactory",
    eventName: "PoolCreated",
    fromBlock: FROM_BLOCK_NUMBER,
  });

  const { data: productPoolHistory, isLoading: isLoadingProductPoolHistory } = useScaffoldEventHistory({
    contractName: "ConstantProductFactory",
    eventName: "PoolCreated",
    fromBlock: FROM_BLOCK_NUMBER,
  });

  // Adds pools deployed using the factories
  useScaffoldEventSubscriber({
    contractName: "ConstantSumFactory",
    eventName: "PoolCreated",
    listener: logs => {
      logs.forEach(log => {
        const { pool } = log.args;
        if (pool) {
          setCreatedPools(pools => [...pools, pool]);
        }
      });
    },
  });

  // Adds pools deployed using the factories
  useScaffoldEventSubscriber({
    contractName: "ConstantProductFactory",
    eventName: "PoolCreated",
    listener: logs => {
      logs.forEach(log => {
        const { pool } = log.args;
        if (pool) {
          setCreatedPools(pools => [...pools, pool]);
        }
      });
    },
  });

  useEffect(() => {
    if (!isLoadingSumPoolHistory && !isLoadingProductPoolHistory && sumPoolHistory && productPoolHistory) {
      const pools = [...sumPoolHistory, ...productPoolHistory]
        .map(({ args }) => {
          if (args.pool && isAddress(args.pool)) return args.pool;
        })
        .filter((pool): pool is Address => typeof pool === "string");
      setCreatedPools(pools);
    }
  }, [sumPoolHistory, productPoolHistory, isLoadingSumPoolHistory, isLoadingProductPoolHistory]);

  return (
    <section className="my-7">
      <div className="mb-4 flex justify-center gap-3">
        {createdPools.length > 0 &&
          createdPools.map(pool => (
            <button
              key={pool}
              className={`btn btn-sm btn-secondary flex relative pl-[35px] border-none font-normal ${
                selectedPoolAddress === pool ? " bg-violet-300 text-neutral-800" : ""
              }`}
              onClick={() => {
                setSelectedPoolAddress(pool);
                router.push(`${pathname}?address=${pool}`);
              }}
            >
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                alt=""
                className={`!rounded-full absolute top-0.5 left-1 `}
                src={blo(pool as `0x${string}`)}
                width="25"
                height="25"
              />
              {pool?.slice(0, 6) + "..." + pool?.slice(-4)}
            </button>
          ))}
      </div>
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
              className={`btn w-16 absolute top-0.5 right-0.5 ${
                isValidAddress ? "bg-violet-300 hover:bg-violet-400" : ""
              }`}
              type="submit"
              disabled={!isValidAddress}
            >
              <MagnifyingGlassIcon className="h-5 w-5" />
            </button>
          </div>
        </form>
      </div>
    </section>
  );
};
