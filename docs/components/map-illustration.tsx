import type { SVGProps } from 'react';

const PIN =
  'M16 2C9.925 2 5 6.925 5 13c0 7.5 9.4 15.9 10.3 16.7a1 1 0 0 0 1.4 0C17.6 28.9 27 20.5 27 13c0-6.075-4.925-11-11-11Z';

interface PinProps {
  x: number;
  y: number;
  scale?: number;
  color?: string;
}

function Pin({
  x,
  y,
  scale = 1.3,
  color = 'var(--color-fd-primary)',
}: PinProps) {
  return (
    <g
      transform={`translate(${x - 16 * scale} ${
        y - 30 * scale
      }) scale(${scale})`}
    >
      <ellipse
        cx="16"
        cy="31"
        rx="7"
        ry="2.5"
        fill="var(--color-fd-foreground)"
        opacity="0.15"
      />
      <path d={PIN} fill={color} />
      <circle cx="16" cy="13" r="4.5" fill="var(--color-fd-background)" />
    </g>
  );
}

const GAP = 12;
const COL_WIDTHS = [96, 118, 84, 128, 104, 92, 118];
const ROW_HEIGHTS = [84, 108, 72, 116, 96, 104, 84, 120];

interface Block {
  x: number;
  y: number;
  w: number;
  h: number;
  col: number;
  row: number;
}

function buildBlocks(): Block[] {
  const blocks: Block[] = [];
  let y = 0;
  ROW_HEIGHTS.forEach((h, row) => {
    let x = 0;
    COL_WIDTHS.forEach((w, col) => {
      blocks.push({ x, y, w, h, col, row });
      x += w + GAP;
    });
    y += h + GAP;
  });
  return blocks;
}

const BLOCKS = buildBlocks();
const PARK = BLOCKS.find((b) => b.col === 4 && b.row === 4)!;
const PLAZA = BLOCKS.find((b) => b.col === 2 && b.row === 2)!;

const ROUTE =
  'M430 790 L 430 620 L 350 620 L 350 330 L 520 330 L 520 260 L 660 260';

export function MapIllustration(props: SVGProps<SVGSVGElement>) {
  return (
    <svg
      viewBox="0 0 800 860"
      preserveAspectRatio="xMidYMid slice"
      xmlns="http://www.w3.org/2000/svg"
      aria-hidden
      {...props}
    >
      {/* city blocks: roads are the gaps between them */}
      <g
        fill="var(--color-fd-foreground)"
        fillOpacity="0.045"
        stroke="var(--color-fd-border)"
        strokeOpacity="0.7"
        strokeWidth="1"
      >
        {BLOCKS.map((b) => {
          if (b === PARK || b === PLAZA) return null;
          const split = (b.col + b.row) % 3 === 0 && b.w > 100;
          if (split) {
            const half = (b.w - GAP / 2) / 2;
            return (
              <g key={`${b.col}-${b.row}`}>
                <rect x={b.x} y={b.y} width={half} height={b.h} rx="4" />
                <rect
                  x={b.x + half + GAP / 2}
                  y={b.y}
                  width={half}
                  height={b.h}
                  rx="4"
                />
              </g>
            );
          }
          return (
            <rect
              key={`${b.col}-${b.row}`}
              x={b.x}
              y={b.y}
              width={b.w}
              height={b.h}
              rx="4"
            />
          );
        })}
      </g>

      {/* park + plaza */}
      <rect
        x={PARK.x}
        y={PARK.y}
        width={PARK.w}
        height={PARK.h}
        rx="6"
        fill="#34A853"
        opacity="0.18"
      />
      <rect
        x={PLAZA.x}
        y={PLAZA.y}
        width={PLAZA.w}
        height={PLAZA.h}
        rx="6"
        fill="var(--color-fd-primary)"
        opacity="0.08"
      />

      {/* avenues cut through the blocks */}
      <g
        stroke="var(--color-fd-background)"
        strokeWidth="18"
        strokeLinecap="round"
        fill="none"
      >
        <path d="M0 700 L 800 160" />
        <path d="M480 860 C 540 660, 640 520, 800 470" />
      </g>
      <g
        stroke="var(--color-fd-border)"
        strokeWidth="1"
        strokeDasharray="6 10"
        strokeLinecap="round"
        fill="none"
        opacity="0.8"
      >
        <path d="M0 700 L 800 160" />
        <path d="M480 860 C 540 660, 640 520, 800 470" />
      </g>

      {/* water */}
      <path
        d="M560 860 C 620 780, 720 740, 800 720 L 800 860 Z"
        fill="var(--color-fd-primary)"
        opacity="0.1"
      />

      {/* circle overlay */}
      <circle
        cx="600"
        cy="620"
        r="62"
        fill="var(--color-fd-primary)"
        fillOpacity="0.1"
        stroke="var(--color-fd-primary)"
        strokeOpacity="0.5"
        strokeWidth="1.5"
      />

      {/* route */}
      <path
        d={ROUTE}
        fill="none"
        stroke="var(--color-fd-primary)"
        strokeOpacity="0.18"
        strokeWidth="12"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path
        className="map-route"
        d={ROUTE}
        fill="none"
        stroke="var(--color-fd-primary)"
        strokeWidth="4"
        strokeLinecap="round"
        strokeLinejoin="round"
        pathLength={1}
      />

      {/* callout */}
      <g transform="translate(560 160)">
        <rect
          width="200"
          height="44"
          rx="10"
          fill="var(--color-fd-background)"
          stroke="var(--color-fd-border)"
        />
        <path
          d="M92 44 L 100 54 L 108 44 Z"
          fill="var(--color-fd-background)"
          stroke="var(--color-fd-border)"
        />
        <rect
          x="93"
          y="43"
          width="14"
          height="2"
          fill="var(--color-fd-background)"
        />
        <circle cx="24" cy="22" r="6" fill="var(--color-fd-primary)" />
        <rect
          x="40"
          y="13"
          width="110"
          height="7"
          rx="3.5"
          fill="var(--color-fd-foreground)"
          opacity="0.7"
        />
        <rect
          x="40"
          y="26"
          width="70"
          height="5"
          rx="2.5"
          fill="var(--color-fd-muted-foreground)"
          opacity="0.6"
        />
      </g>

      <Pin x={430} y={790} />
      <Pin x={660} y={260} color="#EA4335" />
      <Pin x={600} y={620} scale={1} />
    </svg>
  );
}
