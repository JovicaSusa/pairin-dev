import { useState } from "react";
import { Check, ChevronsUpDown, Plus } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Popover, PopoverTrigger, PopoverContent } from "@/components/ui/popover";
import { Command, CommandInput, CommandList, CommandEmpty, CommandGroup, CommandItem } from "@/components/ui/command";
import { cn } from "@/lib/utils";

export default function TagCombobox({ tags, value, onChange }) {
  const [open, setOpen] = useState(false);
  const [search, setSearch] = useState("");

  const filtered = tags.filter((tag) => tag.label.toLowerCase().includes(search.toLowerCase()));
  const exactMatch = tags.some((tag) => tag.label.toLowerCase() === search.trim().toLowerCase());

  const select = (name) => {
    onChange(name);
    setSearch("");
    setOpen(false);
  };

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <Button
          type="button"
          variant="neutral"
          role="combobox"
          aria-expanded={open}
          className="w-full justify-between font-normal"
        >
          <span className={cn("truncate", !value && "text-black/40")}>
            {value || "Search or create..."}
          </span>
          <ChevronsUpDown className="h-4 w-4 shrink-0 opacity-50" />
        </Button>
      </PopoverTrigger>
      <PopoverContent
        align="start"
        className="w-[var(--radix-popover-trigger-width)] bg-secondary-background p-0 text-foreground"
      >
        <Command shouldFilter={false}>
          <CommandInput value={search} onValueChange={setSearch} placeholder="Search or create..." />
          <CommandList>
            {filtered.length === 0 && <CommandEmpty>No matching tags.</CommandEmpty>}
            <CommandGroup>
              {filtered.map((tag) => (
                <CommandItem key={tag.value} value={tag.label} onSelect={() => select(tag.label)}>
                  <Check className={cn("h-4 w-4", value === tag.label ? "opacity-100" : "opacity-0")} />
                  {tag.label}
                </CommandItem>
              ))}
              {search.trim() && !exactMatch && (
                <CommandItem value={search} onSelect={() => select(search.trim())}>
                  <Plus className="h-4 w-4" />
                  Create "{search.trim()}"
                </CommandItem>
              )}
            </CommandGroup>
          </CommandList>
        </Command>
      </PopoverContent>
    </Popover>
  );
}
