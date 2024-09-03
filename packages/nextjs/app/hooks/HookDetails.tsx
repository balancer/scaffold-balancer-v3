"use client";

import { useState } from "react";
import Link from "next/link";
import { type HookInfo } from "./page";
import { ArrowTopRightOnSquareIcon } from "@heroicons/react/24/outline";
import Modal from "~~/components/common/Modal";

export const HooksDetails = ({ hooks }: { hooks: HookInfo[] }) => {
  const [activeModal, setActiveModal] = useState<number | null>(null);

  const modalContent = (id: number) => {
    if (!hooks) return null;
    const hook = hooks.find(hook => hook.id === id);
    if (!hook) return null;
    const categories = hook.category.join(", ");
    return (
      <div className="text-lg  flex flex-col gap-10">
        <div>
          <h1 className="text-3xl font-bold mb-1">{hook.title}</h1>
          <div>Created By {hook.created_by}</div>
        </div>

        <div className="text-xl">{hook.description}</div>

        <div className="flex flex-col md:flex-row flex-wrap md:justify-between">
          <div>Audited: {hook.audited}</div>
          <div>Categories: {categories}</div>
          <Link
            href={hook.github}
            rel="noopener noreferrer"
            target="_blank"
            className="link flex items-center gap-2 hover:text-violet-400"
          >
            View on Github <GithubIcon />
          </Link>
        </div>
      </div>
    );
  };

  return (
    <>
      {hooks.map(hook => (
        <div
          key={hook.id}
          className="text-lg bg-base-200 hover:bg-base-100 p-5 rounded-lg w-full hover:cursor-pointer  grid grid-cols-5 shadow-md"
          onClick={() => setActiveModal(hook.id)}
        >
          <div className="col-span-full lg:col-start-1 lg:col-end-3 text-xl font-bold ">{hook.title}</div>

          <div className="hidden lg:flex text-center">
            <Link
              className="hover:underline hover:text-accent flex gap-2 items-center text-nowrap overflow-hidden whitespace-nowrap"
              target="_blank"
              rel="noopener noreferrer"
              href={hook.github}
            >
              github <ArrowTopRightOnSquareIcon className="w-4 h-4" />
            </Link>
          </div>

          <div className="hidden lg:flex">{hook.category}</div>
          <div className="hidden lg:flex">{hook.created_by}</div>
        </div>
      ))}

      {activeModal && (
        <Modal isOpen={activeModal !== null} onClose={() => setActiveModal(null)}>
          {modalContent(activeModal)}
        </Modal>
      )}
    </>
  );
};

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
