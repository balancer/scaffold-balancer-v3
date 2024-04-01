import { Fragment } from "react";
import { ChevronDownIcon } from "@heroicons/react/24/outline";

export const Join = () => {
  return (
    <Fragment>
      <div className="mb-5">
        <div>
          <label>Tokens In</label>
        </div>
        <div className="relative">
          <input type="number" className="text-2xl w-full input input-bordered rounded-lg bg-base-200 p-10" />
          <div className="dropdown dropdown-end absolute top-3 right-4 ">
            <div tabIndex={0} role="button" className="btn m-1 btn-accent rounded-lg w-24">
              DAI <ChevronDownIcon className="w-4 h-4" />
            </div>
            <ul tabIndex={0} className="dropdown-content z-[1] menu p-2 shadow bg-base-100 rounded-box w-52">
              <li>
                <a>Item 1</a>
              </li>
              <li>
                <a>Item 2</a>
              </li>
            </ul>
          </div>
        </div>
      </div>
      <div className="mb-5">
        <div className="relative">
          <input type="number" className="text-2xl w-full input input-bordered rounded-lg bg-base-200 p-10" />
          <div className="dropdown dropdown-end absolute top-3 right-4 ">
            <div tabIndex={0} role="button" className="btn m-1 btn-accent rounded-lg w-24">
              USDe <ChevronDownIcon className="w-4 h-4" />
            </div>
            <ul tabIndex={0} className="dropdown-content z-[1] menu p-2 shadow bg-base-100 rounded-box w-52">
              <li>
                <a>Item 1</a>
              </li>
              <li>
                <a>Item 2</a>
              </li>
            </ul>
          </div>
        </div>
      </div>
      <div>
        <button className="btn btn-accent mt-3 w-full rounded-lg">Query Join</button>
      </div>
    </Fragment>
  );
};
