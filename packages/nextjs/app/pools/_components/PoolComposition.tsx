/**
 * Display a pool's token composition including the tokens' address, balance, and weight
 */
export const PoolComposition = () => {
  return (
    <div className="w-full">
      <h5 className="text-2xl font-bold mb-3">Composition</h5>
      <SkeletonLoader />
    </div>
  );
};

const SkeletonLoader = () => {
  return <div className="animate-pulse bg-base-200 rounded-xl w-full h-72"></div>;
};
