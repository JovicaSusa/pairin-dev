import { useState } from "react";
import { format } from "date-fns";
import { CalendarIcon } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { Calendar } from "@/components/ui/calendar";

const parseLocalDate = (str) => {
  if (!str) return undefined;
  const [year, month, day] = str.split('-').map(Number);
  return new Date(year, month - 1, day);
};

export default function FilterForm({ tags, userLevels, languages, filters = {}, onSubmit }) {
  const [form, setForm] = useState({
    tags_name_eq: filters.tags_name_eq || "",
    duration_eq: filters.duration_eq || "",
    user_level_eq: filters.user_level_eq || "",
    user_language_eq: filters.user_language_eq || "",
    periods_start_at_gteq: filters.periods_start_at_gteq || "",
    periods_start_at_lteq: filters.periods_start_at_lteq || "",
  });

  const handleChange = (e) => {
    const { name, value } = e.target;
    setForm({ ...form, [name]: value });
  };

  const handleSelectChange = (name, value) => {
    setForm({ ...form, [name]: value });
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    onSubmit(form);
  };

  return (
    <form
      className="flex flex-col gap-4 mb-12 md:flex-row md:flex-wrap md:justify-between"
      onSubmit={handleSubmit}
    >
      <div className="md:w-5/12">
        <Label htmlFor="tags_name_eq" className="block mb-1">
          Tags
        </Label>
        <Select value={form.tags_name_eq} onValueChange={(val) => handleSelectChange("tags_name_eq", val)}>
          <SelectTrigger className="w-full">
            <SelectValue placeholder="Select tag" />
          </SelectTrigger>
          <SelectContent>
            {tags.map((tag) => (
              <SelectItem key={tag.id} value={tag.name}>{tag.name}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <div className="md:w-5/12">
        <Label htmlFor="duration_eq" className="block mb-1">
          Duration
        </Label>
        <Input
          type="number"
          id="duration_eq"
          name="duration_eq"
          value={form.duration_eq}
          onChange={handleChange}
          placeholder="Duration in minutes"
        />
      </div>

      <div className="md:w-5/12">
        <Label htmlFor="user_level_eq" className="block mb-1">
          User level
        </Label>
        <Select value={form.user_level_eq} onValueChange={(val) => handleSelectChange("user_level_eq", val)}>
          <SelectTrigger className="w-full">
            <SelectValue placeholder="Select level" />
          </SelectTrigger>
          <SelectContent>
            {userLevels.map((lvl) => (
              <SelectItem key={lvl} value={lvl}>{lvl.charAt(0).toUpperCase() + lvl.slice(1)}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <div className="md:w-5/12">
        <Label htmlFor="user_language_eq" className="block mb-1">
          User language
        </Label>
        <Select value={form.user_language_eq} onValueChange={(val) => handleSelectChange("user_language_eq", val)}>
          <SelectTrigger className="w-full">
            <SelectValue placeholder="Select language" />
          </SelectTrigger>
          <SelectContent>
            {languages.map(([name, code]) => (
              <SelectItem key={code} value={code}>{name}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <div className="md:w-5/12">
        <Label className="block mb-1">Session starts after</Label>
        <Popover>
          <PopoverTrigger asChild>
            <Button variant="neutral" className="w-full justify-start font-base">
              <CalendarIcon className="mr-2 h-4 w-4" />
              {form.periods_start_at_gteq ? format(parseLocalDate(form.periods_start_at_gteq), "PPP") : <span className="text-muted-foreground">Pick a date</span>}
            </Button>
          </PopoverTrigger>
          <PopoverContent className="w-auto p-0">
            <Calendar
              mode="single"
              selected={parseLocalDate(form.periods_start_at_gteq)}
              onSelect={(date) => handleSelectChange("periods_start_at_gteq", date ? format(date, 'yyyy-MM-dd') : "")}
              initialFocus
            />
          </PopoverContent>
        </Popover>
      </div>

      <div className="md:w-5/12">
        <Label className="block mb-1">Session starts before</Label>
        <Popover>
          <PopoverTrigger asChild>
            <Button variant="neutral" className="w-full justify-start font-base">
              <CalendarIcon className="mr-2 h-4 w-4" />
              {form.periods_start_at_lteq ? format(parseLocalDate(form.periods_start_at_lteq), "PPP") : <span className="text-muted-foreground">Pick a date</span>}
            </Button>
          </PopoverTrigger>
          <PopoverContent className="w-auto p-0">
            <Calendar
              mode="single"
              selected={parseLocalDate(form.periods_start_at_lteq)}
              onSelect={(date) => handleSelectChange("periods_start_at_lteq", date ? format(date, 'yyyy-MM-dd') : "")}
              initialFocus
            />
          </PopoverContent>
        </Popover>
      </div>

      <div className="md:w-full flex justify-center mt-6">
        <Button type="submit" size="lg">
          Search
        </Button>
      </div>
    </form>
  );
}
