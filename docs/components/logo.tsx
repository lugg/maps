import type { SVGProps } from 'react';

export function Logo(props: SVGProps<SVGSVGElement>) {
  return (
    <svg
      viewBox="0 0 32 32"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      aria-hidden
      {...props}
    >
      <path
        d="M16 2C9.925 2 5 6.925 5 13c0 7.5 9.4 15.9 10.3 16.7a1 1 0 0 0 1.4 0C17.6 28.9 27 20.5 27 13c0-6.075-4.925-11-11-11Z"
        fill="#4285F4"
      />
      <circle cx="16" cy="13" r="4.5" fill="white" />
    </svg>
  );
}
