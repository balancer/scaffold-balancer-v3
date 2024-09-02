import { SkeletonLoader } from "~~/components/common";

export const PoolPageSkeleton = () => {
  return (
    <div className="w-full">
      <div className="grid grid-cols-1 xl:grid-cols-2 w-full gap-7 mb-5 mt-20">
        <div className="flex flex-col gap-7">
          <div className="w-full h-72">
            <SkeletonLoader />
          </div>
          <div className="w-full h-48">
            <SkeletonLoader />
          </div>
          <div className="w-full h-96">
            <SkeletonLoader />
          </div>
        </div>
        <div className="flex flex-col gap-7">
          <div className="w-full h-96">
            <SkeletonLoader />
          </div>
          <div className="w-full h-72">
            <SkeletonLoader />
          </div>
        </div>
      </div>
    </div>
  );
};
