import { useState, useEffect, useRef } from "react";

export default function ExpandableText({ children, className = "" }) {
  const [expanded, setExpanded] = useState(false);
  const [showButton, setShowButton] = useState(false);
  const contentRef = useRef(null);

  useEffect(() => {
    const el = contentRef.current;
    if (!el) return;
    setShowButton(el.scrollHeight > el.clientHeight);
  }, [children]);

  return (
    <>
      <p ref={contentRef} className={`${expanded ? "" : "line-clamp-3"} ${className}`.trim()}>
        {children}
      </p>
      {showButton && (
        <button
          className="mt-2 text-sm font-bold underline hover:text-purple"
          onClick={() => setExpanded(prev => !prev)}
        >
          {expanded ? "Read less" : "Read more"}
        </button>
      )}
    </>
  );
}
