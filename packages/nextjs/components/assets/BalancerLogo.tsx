import { SVGProps } from "react";

export function BalancerLogo(props: SVGProps<SVGSVGElement>) {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 26 21" {...props}>
      <path
        fill="currentColor"
        // eslint-disable-next-line max-len
        d="M13.202 5.188c4.08 0 7.389-1.105 7.389-2.469 0-1.364-3.308-2.469-7.39-2.469-4.08 0-7.388 1.105-7.388 2.47 0 1.363 3.308 2.468 7.389 2.468Z"
      />
      <path
        fill="currentColor"
        fillRule="evenodd"
        // eslint-disable-next-line max-len
        d="M18.181 12.37c4.321.639 7.336 2.084 7.336 3.765 0 2.272-5.514 4.115-12.315 4.115C6.4 20.25.886 18.407.886 16.135c0-1.68 3.015-3.126 7.337-3.765 1.484.302 3.179.473 4.979.473a25.4 25.4 0 0 0 4.867-.45l.112-.023ZM16.32 5.603c3.914.436 6.735 1.67 6.735 3.124 0 1.819-4.41 3.293-9.852 3.293-5.441 0-9.852-1.474-9.852-3.293 0-1.454 2.821-2.688 6.735-3.124a19.44 19.44 0 0 0 3.117.244c1.066 0 2.084-.08 3.016-.227l.1-.017Z"
        clipRule="evenodd"
      />
    </svg>
  );
}
