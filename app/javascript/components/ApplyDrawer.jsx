import { useEffect } from "react";
import { X } from "lucide-react";
import ApplicationForm from "@/components/ApplicationForm";

export default function ApplyDrawer({ pairRequest, options, needsLevel, onClose }) {
  useEffect(() => {
    const onKey = (e) => {
      // A Select that's open closes first and handles its own Escape.
      if (e.key === "Escape" && !document.querySelector('[role="listbox"]')) onClose();
    };
    const overflow = document.body.style.overflow;

    document.addEventListener("keydown", onKey);
    document.body.style.overflow = "hidden";

    return () => {
      document.removeEventListener("keydown", onKey);
      document.body.style.overflow = overflow;
    };
  }, [onClose]);

  const posterName = pairRequest.user.name || "the poster";

  return (
    <div className="fixed inset-0 z-40 flex justify-end bg-black/40" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div
        role="dialog"
        aria-modal="true"
        aria-label={`Apply to ${posterName}`}
        className="h-full w-full max-w-md overflow-y-auto border-l-2 border-black bg-white p-5"
      >
        <div className="mb-4 flex items-start justify-between gap-3">
          <div className="min-w-0">
            <h2 className="text-2xl">Apply to {posterName}</h2>
            <p className="mt-1 font-bold">{pairRequest.subject}</p>
            <p className="mt-1 whitespace-pre-wrap text-sm text-black/50">{pairRequest.description}</p>
          </div>
          <button type="button" aria-label="Close" onClick={onClose} className="shrink-0">
            <X />
          </button>
        </div>

        <ApplicationForm pairRequest={pairRequest} options={options} needsLevel={needsLevel} onSuccess={onClose} />
      </div>
    </div>
  );
}
