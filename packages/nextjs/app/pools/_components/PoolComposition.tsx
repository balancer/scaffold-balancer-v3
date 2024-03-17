import { SkeletonLoader } from "~~/components/common";

/**
 * Display a pool's token composition including the tokens' address, balance, and weight
 */
export const PoolComposition = () => {
  return (
    <div className="w-full flex flex-col">
      <h5 className="text-2xl font-bold mb-3">Composition</h5>
      <SkeletonLoader />
    </div>
  );
};
