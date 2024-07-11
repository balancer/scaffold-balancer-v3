"use client";

import { useState } from "react";
import Link from "next/link";
import type { NextPage } from "next";
import Modal from "~~/components/common/Modal";
import { useHooks } from "~~/hooks/balancer/useHooks";

const Hooks: NextPage = () => {
  const [activeModal, setActiveModal] = useState<number | null>(null);

  const { data: hooks, isError, isFetching } = useHooks();

  if (isError === true) {
    return <div>Error fetching hooks data</div>;
  }

  const modalContent = (id: number) => {
    if (!hooks) return null;
    const hook = hooks.find(hook => hook.id === id);
    if (!hook) return null;
    const categories = hook.category.join(", ");
    return (
      <div className="text-lg">
        <h1 className="text-3xl font-bold mb-1">{hook.title}</h1>
        <div className="">Created By {hook.created_by}</div>
        <p className="text-xl">{hook.description}</p>
        <div>Audited: {hook.audited}</div>
        <div className="flex justify-between">
          <div>Categories: {categories}</div>
          <Link href={hook.github} rel="noopener noreferrer" target="_blank" className="link">
            View on Github
          </Link>
        </div>
      </div>
    );
  };

  return (
    <div className="flex items-center flex-col flex-grow py-7 px-5 md:px-10 xl:px-20 bg-base-300">
      <div className="mb-7 w-full">
        <h1 className="text-3xl md:text-5xl font-bold my-10">🪝 Pool Hooks</h1>
        <p className="text-xl">
          Extend the functionality of liquidity pools with hooks contracts. Consider utilizing one of the examples below
          or{" "}
          <Link
            target="_blank"
            rel="noopener noreferrer"
            href="https://balancer-hooks.vercel.app/submit-hook.html"
            className="link"
          >
            submit your own creation
          </Link>
          .
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 2xl:grid-cols-3 gap-5 w-full">
        {isFetching ? (
          <div>...</div>
        ) : isError ? (
          <div>Error fetching hooks</div>
        ) : (
          hooks?.map(hook => (
            <div
              key={hook.id}
              className="bg-base-200 hover:bg-base-100 p-5 rounded-lg w-full hover:cursor-pointer"
              onClick={() => setActiveModal(hook.id)}
            >
              <div className="mb-3">
                <div className="flex justify-between items-center">
                  <h1 className="text-2xl font-bold mb-0">{hook.title}</h1>
                  <Link target="_blank" rel="noopener noreferrer" href={hook.github}>
                    <GithubIcon />
                  </Link>
                </div>

                <div className="">Created By {hook.created_by}</div>
              </div>
              <div className="text-lg card-description">{hook.description}</div>
            </div>
          ))
        )}
      </div>
      {activeModal && (
        <Modal isOpen={activeModal !== null} onClose={() => setActiveModal(null)}>
          {modalContent(activeModal)}
        </Modal>
      )}
    </div>
  );
};

export default Hooks;

const GithubIcon = () => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    viewBox="0 0 24 24"
    width="30"
    height="30"
    fill="currentColor"
    className="hover:text-violet-400"
  >
    <path d="M12.001 2C6.47598 2 2.00098 6.475 2.00098 12C2.00098 16.425 4.86348 20.1625 8.83848 21.4875C9.33848 21.575 9.52598 21.275 9.52598 21.0125C9.52598 20.775 9.51348 19.9875 9.51348 19.15C7.00098 19.6125 6.35098 18.5375 6.15098 17.975C6.03848 17.6875 5.55098 16.8 5.12598 16.5625C4.77598 16.375 4.27598 15.9125 5.11348 15.9C5.90098 15.8875 6.46348 16.625 6.65098 16.925C7.55098 18.4375 8.98848 18.0125 9.56348 17.75C9.65098 17.1 9.91348 16.6625 10.201 16.4125C7.97598 16.1625 5.65098 15.3 5.65098 11.475C5.65098 10.3875 6.03848 9.4875 6.67598 8.7875C6.57598 8.5375 6.22598 7.5125 6.77598 6.1375C6.77598 6.1375 7.61348 5.875 9.52598 7.1625C10.326 6.9375 11.176 6.825 12.026 6.825C12.876 6.825 13.726 6.9375 14.526 7.1625C16.4385 5.8625 17.276 6.1375 17.276 6.1375C17.826 7.5125 17.476 8.5375 17.376 8.7875C18.0135 9.4875 18.401 10.375 18.401 11.475C18.401 15.3125 16.0635 16.1625 13.8385 16.4125C14.201 16.725 14.5135 17.325 14.5135 18.2625C14.5135 19.6 14.501 20.675 14.501 21.0125C14.501 21.275 14.6885 21.5875 15.1885 21.4875C19.259 20.1133 21.9999 16.2963 22.001 12C22.001 6.475 17.526 2 12.001 2Z"></path>
  </svg>
);
