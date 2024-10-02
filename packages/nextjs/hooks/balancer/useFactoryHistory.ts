import { useEffect, useState } from "react";
import { type Address, isAddress } from "viem";
import { useScaffoldEventHistory, useScaffoldEventSubscriber } from "~~/hooks/scaffold-eth";

// TODO: Figure out if this can be dynamically set. Maybe write the block number as user starts a fork?
const FROM_BLOCK_NUMBER = 6563900n;

export const useFactoryHistory = () => {
  const [sumPools, setSumPools] = useState<Address[]>([]);
  const [sumPoolsV2, setSumPoolsV2] = useState<Address[]>([]);
  const [productPools, setProductPools] = useState<Address[]>([]);
  const [weightedPools, setWeightedPools] = useState<Address[]>([]);

  useScaffoldEventSubscriber({
    contractName: "ConstantSumFactory",
    eventName: "PoolCreated",
    listener: logs => {
      logs.forEach(log => {
        const { pool } = log.args;
        if (pool) {
          setSumPools(pools => [...pools, pool]);
        }
      });
    },
  });

  useScaffoldEventSubscriber({
    contractName: "ConstantSumFactoryV2",
    eventName: "PoolCreated",
    listener: logs => {
      logs.forEach(log => {
        const { pool } = log.args;
        if (pool) {
          setSumPoolsV2(pools => [...pools, pool]);
        }
      });
    },
  });

  useScaffoldEventSubscriber({
    contractName: "ConstantProductFactory",
    eventName: "PoolCreated",
    listener: logs => {
      logs.forEach(log => {
        const { pool } = log.args;
        if (pool) {
          setProductPools(pools => [...pools, pool]);
        }
      });
    },
  });

  useScaffoldEventSubscriber({
    contractName: "WeightedPoolFactory",
    eventName: "PoolCreated",
    listener: logs => {
      logs.forEach(log => {
        const { pool } = log.args;
        if (pool) {
          setWeightedPools(pools => [...pools, pool]);
        }
      });
    },
  });

  // Fetches the history of pools deployed via factory
  const { data: sumPoolHistory, isLoading: isLoadingSumPoolHistory } = useScaffoldEventHistory({
    contractName: "ConstantSumFactory",
    eventName: "PoolCreated",
    fromBlock: FROM_BLOCK_NUMBER,
  });

  const { data: sumPoolHistoryV2, isLoading: isLoadingSumPoolHistoryV2 } = useScaffoldEventHistory({
    contractName: "ConstantSumFactoryV2",
    eventName: "PoolCreated",
    fromBlock: FROM_BLOCK_NUMBER,
  });

  const { data: productPoolHistory, isLoading: isLoadingProductPoolHistory } = useScaffoldEventHistory({
    contractName: "ConstantProductFactory",
    eventName: "PoolCreated",
    fromBlock: FROM_BLOCK_NUMBER,
  });

  const { data: weightedPoolHistory, isLoading: isLoadingWeightedPoolHistory } = useScaffoldEventHistory({
    contractName: "WeightedPoolFactory",
    eventName: "PoolCreated",
    fromBlock: FROM_BLOCK_NUMBER,
  });

  useScaffoldEventSubscriber({
    contractName: "ConstantSumFactory",
    eventName: "PoolCreated",
    listener: logs => {
      logs.forEach(log => {
        const { pool } = log.args;
        if (pool) {
          setSumPools(pools => [...pools, pool]);
        }
      });
    },
  });

  useScaffoldEventSubscriber({
    contractName: "ConstantSumFactoryV2",
    eventName: "PoolCreated",
    listener: logs => {
      logs.forEach(log => {
        const { pool } = log.args;
        if (pool) {
          setSumPools(pools => [...pools, pool]);
        }
      });
    },
  });

  useScaffoldEventSubscriber({
    contractName: "ConstantProductFactory",
    eventName: "PoolCreated",
    listener: logs => {
      logs.forEach(log => {
        const { pool } = log.args;
        if (pool) {
          setProductPools(pools => [...pools, pool]);
        }
      });
    },
  });

  useScaffoldEventSubscriber({
    contractName: "WeightedPoolFactory",
    eventName: "PoolCreated",
    listener: logs => {
      logs.forEach(log => {
        const { pool } = log.args;
        if (pool) {
          setWeightedPools(pools => [...pools, pool]);
        }
      });
    },
  });

  useEffect(
    () => {
      if (
        !isLoadingSumPoolHistory &&
        !isLoadingSumPoolHistoryV2 &&
        !isLoadingProductPoolHistory &&
        !isLoadingWeightedPoolHistory &&
        sumPoolHistory &&
        sumPoolHistoryV2 &&
        productPoolHistory &&
        weightedPoolHistory
      ) {
        const sumPools = sumPoolHistory
          .map(({ args }) => {
            if (args.pool && isAddress(args.pool)) return args.pool;
          })
          .filter((pool): pool is Address => typeof pool === "string");

        const sumPoolsV2 = sumPoolHistoryV2
          .map(({ args }) => {
            if (args.pool && isAddress(args.pool)) return args.pool;
          })
          .filter((pool): pool is Address => typeof pool === "string");

        const productPools = productPoolHistory
          .map(({ args }) => {
            if (args.pool && isAddress(args.pool)) return args.pool;
          })
          .filter((pool): pool is Address => typeof pool === "string");

        const weightedPools = weightedPoolHistory
          .map(({ args }) => {
            if (args.pool && isAddress(args.pool)) return args.pool;
          })
          .filter((pool): pool is Address => typeof pool === "string");

        setProductPools(productPools);
        setSumPools(sumPools);
        setSumPoolsV2(sumPoolsV2);
        setWeightedPools(weightedPools);
      }
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [
      sumPoolHistory,
      productPoolHistory,
      weightedPoolHistory,
      isLoadingSumPoolHistory,
      isLoadingProductPoolHistory,
      isLoadingWeightedPoolHistory,
    ],
  );

  return { sumPools, sumPoolsV2, productPools, weightedPools };
};
