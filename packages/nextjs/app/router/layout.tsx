import { getMetadata } from "~~/utils/scaffold-eth/getMetadata";

export const metadata = getMetadata({
  title: "Smart Order Router",
  description: "...",
});

const RouterLayout = ({ children }: { children: React.ReactNode }) => {
  return (
    <>
      <div className="flex-grow bg-base-300">
        <div className="max-w-screen-2xl mx-auto">{children}</div>
      </div>
    </>
  );
};

export default RouterLayout;
