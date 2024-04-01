export const PoolAlert = ({ isRegistered }: { isRegistered: boolean }) => {
  const text = isRegistered ? "initialized" : "registered";
  return (
    <div className="w-full">
      <div role="alert" className="alert alert-warning justify-center flex flex-wrap rounded-lg">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          className="stroke-current shrink-0 h-6 w-6"
          fill="none"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth="2"
            d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
          />
        </svg>
        <span>
          This pool has not been {text}. Check out our{" "}
          <a
            rel="noopener"
            target="_blank"
            className="underline text-blue-700"
            href="https://github.com/Dev-Rel-as-a-Service/scaffold-balancer-v3?tab=readme-ov-file#15-initialize-the-pool"
          >
            how to guide
          </a>
        </span>
      </div>
    </div>
  );
};
