/**
 * SEG logo, recreated as vector art to match the Social Enterprise Ghana mark:
 * an orange lightbulb whose glass holds two meshing gears (the "O" of SOCIAL),
 * with "SOCIAL" set heavy and "ENTERPRISE GHANA" beneath it.
 */
type BulbProps = {
  className?: string;
  animated?: boolean;
  title?: string;
};

function Gear({
  cx,
  cy,
  r,
  teeth,
  spin,
}: {
  cx: number;
  cy: number;
  r: number;
  teeth: number;
  spin: "cw" | "ccw" | false;
}) {
  const toothW = r * 0.42;
  const toothH = r * 0.5;
  const arr = Array.from({ length: teeth });
  return (
    <g
      style={{
        transformBox: "fill-box",
        transformOrigin: "center",
        animation: spin === "cw" ? "spin-slow 9s linear infinite" : spin === "ccw" ? "spin-rev 7s linear infinite" : undefined,
      }}
    >
      {arr.map((_, i) => {
        const a = (360 / teeth) * i;
        return (
          <rect
            key={i}
            x={cx - toothW / 2}
            y={cy - r - toothH * 0.6}
            width={toothW}
            height={toothH}
            rx={toothW * 0.25}
            fill="#fff"
            transform={`rotate(${a} ${cx} ${cy})`}
          />
        );
      })}
      <circle cx={cx} cy={cy} r={r} fill="#fff" />
      <circle cx={cx} cy={cy} r={r * 0.42} fill="#f7941d" />
    </g>
  );
}

export function Bulb({ className, animated = false, title }: BulbProps) {
  return (
    <svg viewBox="0 0 100 132" className={className} role="img" aria-label={title ?? "SEG bulb"}>
      {/* soft glow */}
      <circle cx="50" cy="46" r="40" fill="#f7941d" opacity={animated ? 0.18 : 0} className={animated ? "anim-pulse-glow" : ""} />
      {/* glass bulb */}
      <path
        d="M50 6c-21 0-37 16-37 36 0 13 7 22 14 30 4 4.5 6 8 7 12h32c1-4 3-7.5 7-12 7-8 14-17 14-30 0-20-16-36-37-36Z"
        fill="#f7941d"
      />
      {/* highlight */}
      <ellipse cx="36" cy="30" rx="9" ry="13" fill="#fff" opacity="0.18" />
      {/* gears */}
      <Gear cx={42} cy={40} r={13} teeth={8} spin={animated ? "cw" : false} />
      <Gear cx={64} cy={52} r={9} teeth={7} spin={animated ? "ccw" : false} />
      {/* screw base */}
      <rect x="34" y="86" width="32" height="7" rx="3.5" fill="#f7941d" />
      <rect x="37" y="95" width="26" height="7" rx="3.5" fill="#f7941d" />
      <rect x="40" y="104" width="20" height="7" rx="3.5" fill="#f7941d" />
      <path d="M44 113h12l-2.5 8a3.5 3.5 0 0 1-7 0L44 113Z" fill="#f7941d" />
    </svg>
  );
}

export function Logo({
  className = "",
  animated = false,
  tone = "brand",
}: {
  className?: string;
  animated?: boolean;
  tone?: "brand" | "light";
}) {
  const word = tone === "light" ? "#fff" : "#f7941d";
  return (
    <span className={`inline-flex flex-col leading-none ${className}`}>
      <span className="inline-flex items-center font-display font-extrabold tracking-[-0.02em] text-[1em]" style={{ color: word }}>
        <span>S</span>
        <Bulb animated={animated} className="mx-[0.02em] h-[1.12em] w-auto translate-y-[0.04em]" />
        <span>CIAL</span>
      </span>
      <span className="mt-[0.12em] inline-flex items-baseline gap-[0.4em] font-display font-extrabold tracking-[0.12em] text-[0.3em]">
        <span style={{ color: word }}>ENTERPRISE</span>
        <span
          style={
            tone === "light"
              ? { WebkitTextStroke: "1px rgba(255,255,255,0.9)", color: "transparent" }
              : { WebkitTextStroke: "1.4px #f7941d", color: "transparent" }
          }
        >
          GHANA
        </span>
      </span>
    </span>
  );
}
