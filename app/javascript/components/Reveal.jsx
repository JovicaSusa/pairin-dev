import { useState } from "react";

export default function Reveal({ children, button, defaultOpen = false }) {
  const [open, setOpen] = useState(defaultOpen);

  return (
    <div className="w-full">
      <div onClick={() => setOpen(!open)}>
        {button}
      </div>

      <div className={open ? "" : "hidden"}>
        {children}
      </div>
    </div>
  );
}
