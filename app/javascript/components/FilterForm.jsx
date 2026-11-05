import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";

export default function FilterForm({ tags, commitments, userLevels, languages, filters = {}, onSubmit }) {
  const [form, setForm] = useState({
    tags_name_eq: filters.tags_name_eq || "",
    commitment_eq: filters.commitment_eq || "",
    user_level_eq: filters.user_level_eq || "",
    user_language_eq: filters.user_language_eq || "",
  });

  const handleSelectChange = (name, value) => {
    setForm({ ...form, [name]: value });
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    const compacted = Object.fromEntries(Object.entries(form).filter(([, v]) => v !== ""));
    onSubmit(compacted);
  };

  return (
    <form className="flex flex-col gap-5" onSubmit={handleSubmit}>
      <p className="font-headline font-bold text-sm">Refine your search</p>

      <div className="grid grid-cols-1 gap-4">
      <div>
        <Label htmlFor="filter_tags" className="block mb-1">
          Tags
        </Label>
        <Select value={form.tags_name_eq} onValueChange={(val) => handleSelectChange("tags_name_eq", val)}>
          <SelectTrigger id="filter_tags" className="w-full">
            <SelectValue placeholder="Select tag" />
          </SelectTrigger>
          <SelectContent>
            {tags.map((tag) => (
              <SelectItem key={tag.id} value={tag.name}>{tag.name}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <div>
        <Label htmlFor="filter_commitment" className="block mb-1">Commitment</Label>
        <Select value={form.commitment_eq} onValueChange={(val) => handleSelectChange("commitment_eq", val)}>
          <SelectTrigger id="filter_commitment" className="w-full">
            <SelectValue placeholder="Select commitment" />
          </SelectTrigger>
          <SelectContent>
            {commitments.map(({ value, label }) => (
              <SelectItem key={value} value={value}>{label}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <div>
        <Label htmlFor="filter_level" className="block mb-1">
          User level
        </Label>
        <Select value={form.user_level_eq} onValueChange={(val) => handleSelectChange("user_level_eq", val)}>
          <SelectTrigger id="filter_level" className="w-full">
            <SelectValue placeholder="Select level" />
          </SelectTrigger>
          <SelectContent>
            {userLevels.map((lvl) => (
              <SelectItem key={lvl} value={lvl}>{lvl.charAt(0).toUpperCase() + lvl.slice(1)}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <div>
        <Label htmlFor="filter_language" className="block mb-1">
          User language
        </Label>
        <Select value={form.user_language_eq} onValueChange={(val) => handleSelectChange("user_language_eq", val)}>
          <SelectTrigger id="filter_language" className="w-full">
            <SelectValue placeholder="Select language" />
          </SelectTrigger>
          <SelectContent>
            {languages.map(([name, code]) => (
              <SelectItem key={code} value={code}>{name}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      </div>

      <div className="flex justify-end">
        <Button type="submit" size="lg">
          Show results
        </Button>
      </div>
    </form>
  );
}
