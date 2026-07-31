import { useState } from "react";
import { format } from "date-fns";
import { Calendar as CalendarIcon } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Calendar } from "@/components/ui/calendar";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";

const dropdownClassNames = {
  caption_label: "text-sm font-heading px-2 py-1",
  caption_dropdowns: "flex gap-2 justify-center [&>div]:relative",
  dropdown: "absolute inset-0 w-full opacity-0 cursor-pointer",
  vhidden: "sr-only",
};

export function DatePicker({
  value,
  onChange,
  placeholder = "Pick a date",
  fromYear,
  toYear,
  defaultMonth,
  disabled,
  captionLayout = "buttons",
}) {
  const [open, setOpen] = useState(false);
  const selected = value ? new Date(value) : undefined;
  const showDropdowns = captionLayout?.startsWith("dropdown");

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <Button
          type="button"
          variant="noShadow"
          className={`w-full justify-start text-left font-base bg-secondary-background text-foreground ${!selected ? "text-foreground/60" : ""}`}
        >
          <CalendarIcon className="mr-2 h-4 w-4" />
          {selected ? format(selected, "PPP") : placeholder}
        </Button>
      </PopoverTrigger>
      <PopoverContent className="w-auto border-0! p-0" align="start">
        <Calendar
          mode="single"
          selected={selected}
          onSelect={(date) => {
            onChange(date ? format(date, "yyyy-MM-dd") : "");
            setOpen(false);
          }}
          captionLayout={captionLayout}
          fromYear={showDropdowns ? fromYear ?? 1900 : undefined}
          toYear={showDropdowns ? toYear ?? new Date().getFullYear() : undefined}
          defaultMonth={selected ?? defaultMonth}
          disabled={disabled}
          classNames={showDropdowns ? dropdownClassNames : undefined}
          initialFocus
        />
      </PopoverContent>
    </Popover>
  );
}
