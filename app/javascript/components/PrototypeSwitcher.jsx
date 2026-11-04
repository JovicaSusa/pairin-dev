// PROTOTYPE ONLY: floating switcher for throwaway UI prototypes. Never rendered in production builds.
import { useEffect } from "react";

export default function PrototypeSwitcher({ variants, current, onChange, screens, screen, onScreen }) {
  const index = Math.max(0, variants.findIndex((v) => v.key === current));

  const go = (delta) => onChange(variants[(index + delta + variants.length) % variants.length].key);

  useEffect(() => {
    const onKey = (e) => {
      const el = document.activeElement;
      if (el && (el.tagName === "INPUT" || el.tagName === "TEXTAREA" || el.tagName === "SELECT" || el.isContentEditable)) return;
      if (e.key === "ArrowLeft") go(-1);
      if (e.key === "ArrowRight") go(1);
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  });

  if (!import.meta.env.DEV) return null;

  return (
    <div className="fixed bottom-3 left-1/2 z-50 flex max-w-[calc(100vw-1rem)] -translate-x-1/2 flex-col items-center gap-2 rounded-2xl bg-black px-3 py-2 text-xs text-white shadow-xl">
      <div className="flex items-center gap-3 text-sm">
        <button type="button" onClick={() => go(-1)} aria-label="Previous variant" className="px-1">←</button>
        <span className="whitespace-nowrap font-mono">{variants[index].key} — {variants[index].name}</span>
        <button type="button" onClick={() => go(1)} aria-label="Next variant" className="px-1">→</button>
      </div>
      <div className="flex max-w-full gap-1 overflow-x-auto">
        {screens.map((s) => (
          <button
            key={s.key}
            type="button"
            onClick={() => onScreen(s.key)}
            className={`whitespace-nowrap rounded-full px-2 py-1 font-mono ${s.key === screen ? "bg-white text-black" : "text-white/70 hover:text-white"}`}
          >
            {s.name}
          </button>
        ))}
      </div>
    </div>
  );
}
