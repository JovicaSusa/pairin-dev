import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";

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
      className="md:flex md:flex-wrap md:justify-between md:gap-y-4 mb-12"
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
        <Label htmlFor="periods_start_at_gteq" className="block mb-1">
          Session starts after
        </Label>
        <Input
          type="date"
          id="periods_start_at_gteq"
          name="periods_start_at_gteq"
          value={form.periods_start_at_gteq}
          onChange={handleChange}
        />
      </div>

      <div className="md:w-5/12">
        <Label htmlFor="periods_start_at_lteq" className="block mb-1">
          Session starts before
        </Label>
        <Input
          type="date"
          id="periods_start_at_lteq"
          name="periods_start_at_lteq"
          value={form.periods_start_at_lteq}
          onChange={handleChange}
        />
      </div>

      <div className="md:w-full flex justify-center mt-6">
        <Button type="submit" size="lg">
          Search
        </Button>
      </div>
    </form>
  );
}
