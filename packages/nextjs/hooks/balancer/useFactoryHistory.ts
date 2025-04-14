import { useQuery } from "@tanstack/react-query";
import { useScaffoldContract } from "~~/hooks/scaffold-eth";

export const useFactoryHistory = () => {
  // Get contract instances
  const { data: sumFactory } = useScaffoldContract({
    contractName: "ConstantSumFactory",
  });

  const { data: productFactory } = useScaffoldContract({
    contractName: "ConstantProductFactory",
  });

  const { data: weightedFactory } = useScaffoldContract({
    contractName: "WeightedPoolFactory",
  });

  const fetchPoolsFromFactory = async (factory: any) => {
    if (!factory) return [];
    try {
      const poolCount = await factory.read.getPoolCount();
      if (poolCount > 0n) {
        return await factory.read.getPoolsInRange([0n, poolCount]);
      }
      return [];
    } catch (err) {
      console.error("Error fetching pools:", err);
      return [];
    }
  };

  const {
    data: pools,
    isLoading,
    error,
    refetch,
  } = useQuery({
    queryKey: ["pools", sumFactory?.address, productFactory?.address, weightedFactory?.address],
    queryFn: async () => {
      const [sum, product, weighted] = await Promise.all([
        fetchPoolsFromFactory(sumFactory),
        fetchPoolsFromFactory(productFactory),
        fetchPoolsFromFactory(weightedFactory),
      ]);

      return {
        sumPools: sum,
        productPools: product,
        weightedPools: weighted,
      };
    },
    enabled: !!sumFactory && !!productFactory && !!weightedFactory,
    staleTime: 30000, // Consider data fresh for 30 seconds
    gcTime: 5 * 60 * 1000, // Cache for 5 minutes (renamed from cacheTime)
  });

  return {
    sumPools: pools?.sumPools ?? [],
    productPools: pools?.productPools ?? [],
    weightedPools: pools?.weightedPools ?? [],
    isLoading,
    error,
    refresh: refetch,
  };
};
