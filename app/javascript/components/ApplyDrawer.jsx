import { useEffect, useRef } from "react";
import { X } from "lucide-react";
import ApplicationForm from "@/components/ApplicationForm";

const FOCUSABLE = 'a[href], button:not([disabled]), textarea:not([disabled]), input:not([disabled]), select:not([disabled]), [tabindex]:not([tabindex="-1"])';

export default function ApplyDrawer({ pairRequest, options, needsLevel, onClose }) {
  const panel = useRef(null);
  // Read during the first render, before a field in the drawer takes focus.
  const opener = useRef(document.activeElement);

  // Back to what opened it, when that's still on the page.
  useEffect(() => () => {
    if (opener.current?.isConnected) opener.current.focus();
  }, []);

  useEffect(() => {
    const onKey = (e) => {
      // A Select that's open closes first and handles its own keys.
      if (document.querySelector('[role="listbox"]')) return;

      if (e.key === "Escape") onClose();

      // Tab stays inside the drawer.
      if (e.key === "Tab" && panel.current) {
        const items = [...panel.current.querySelectorAll(FOCUSABLE)].filter((el) => el.offsetParent !== null);
        const first = items[0];
        const last = items[items.length - 1];
        if (!panel.current.contains(document.activeElement)) {
          e.preventDefault();
          first?.focus();
        } else if (e.shiftKey && document.activeElement === first) {
          e.preventDefault();
          last?.focus();
        } else if (!e.shiftKey && document.activeElement === last) {
          e.preventDefault();
          first?.focus();
        }
      }
    };
    const overflow = document.body.style.overflow;

    // In the capture phase, to run before the dropdown closes itself: by the
    // time a normal listener runs, it's gone and this would close the drawer too.
    document.addEventListener("keydown", onKey, true);
    document.body.style.overflow = "hidden";

    return () => {
      document.removeEventListener("keydown", onKey, true);
      document.body.style.overflow = overflow;
    };
  }, [onClose]);

  const posterName = pairRequest.user.name || "the poster";

  return (
    <div className="fixed inset-0 z-40 flex justify-end bg-black/40" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div
        ref={panel}
        role="dialog"
        aria-modal="true"
        aria-label={`Apply to ${posterName}`}
        className="h-full w-full max-w-md overflow-y-auto border-l-2 border-black bg-white p-5"
      >
        <div className="mb-4 flex items-start justify-between gap-3">
          <div className="min-w-0">
            <h2 className="text-2xl">Apply to {posterName}</h2>
            <p className="mt-1 font-bold">{pairRequest.subject}</p>
            <p className="mt-1 whitespace-pre-wrap text-sm text-black/65">{pairRequest.description}</p>
          </div>
          <button type="button" aria-label="Close" onClick={onClose} className="-mr-2 -mt-2 flex h-11 w-11 shrink-0 items-center justify-center">
            <X />
          </button>
        </div>

        <ApplicationForm pairRequest={pairRequest} options={options} needsLevel={needsLevel} onSuccess={onClose} />
      </div>
    </div>
  );
}
