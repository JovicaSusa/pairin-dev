import { useState } from "react";

export default function FilterForm({ tags, userLevels, languages, onSubmit }) {
  const [form, setForm] = useState({
    tags_name_eq: "",
    duration_eq: "",
    user_level_eq: "",
    user_language_eq: "",
    starts_after: "",
    starts_before: ""
  });

  const handleChange = (e) => {
    const { name, value } = e.target;
    setForm({ ...form, [name]: value });
  };

  const handleSubmit = (e) => {
    e.preventDefault();

    const payload = {
      ...form,
      periods_start_at_gteq: form.starts_after ? `${form.starts_after}T00:00` : "",
      periods_start_at_lteq: form.starts_before ? `${form.starts_before}T23:59:59` : ""
    };

    delete payload.starts_after;
    delete payload.starts_before;
    onSubmit(payload);
  };

  return (
    <form
      className="md:flex md:flex-wrap md:justify-between md:gap-y-4 mb-12"
      onSubmit={handleSubmit}
    >
      <div className="md:w-5/12">
        <label htmlFor="tags_name_eq" className="font-bold block mb-1">
          Tags
        </label>
        <select
          id="tags_name_eq"
          name="tags_name_eq"
          value={form.tags_name_eq}
          onChange={handleChange}
          className="w-full rounded-md border-2 border-black p-2 font-bold shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] outline-none"
        >
          <option value="">Select tag</option>
          {tags.map((tag) => (
            <option key={tag.id} value={tag.name}>
              {tag.name}
            </option>
          ))}
        </select>
      </div>

      <div className="md:w-5/12">
        <label htmlFor="duration_eq" className="font-bold block mb-1">
          Duration
        </label>
        <input
          type="number"
          id="duration_eq"
          name="duration_eq"
          value={form.duration_eq}
          onChange={handleChange}
          placeholder="Duration in minutes"
          className="w-full rounded-md border-2 border-black p-2 font-bold shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] outline-none"
        />
      </div>

      <div className="md:w-5/12">
        <label htmlFor="user_level_eq" className="font-bold block mb-1">
          User level
        </label>
        <select
          id="user_level_eq"
          name="user_level_eq"
          value={form.user_level_eq}
          onChange={handleChange}
          className="w-full rounded-md border-2 border-black p-2 font-bold shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] outline-none"
        >
          <option value="">Select level</option>
          {userLevels.map((lvl) => (
            <option key={lvl} value={lvl}>
              {lvl.charAt(0).toUpperCase() + lvl.slice(1)}
            </option>
          ))}
        </select>
      </div>

      <div className="md:w-5/12">
        <label htmlFor="user_language_eq" className="font-bold block mb-1">
          User language
        </label>
        <select
          id="user_language_eq"
          name="user_language_eq"
          value={form.user_language_eq}
          onChange={handleChange}
          className="w-full rounded-md border-2 border-black p-2 font-bold shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] outline-none"
        >
          <option value="">Select language</option>
          {languages.map(([name, code]) => (
            <option key={code} value={code}>
              {name}
            </option>
          ))}
        </select>
      </div>

      <div className="md:w-5/12">
        <label htmlFor="starts_after" className="font-bold block mb-1">
          Session starts after
        </label>
        <input
          type="date"
          id="starts_after"
          name="starts_after"
          value={form.starts_after}
          onChange={handleChange}
          className="w-full rounded-md border-2 border-black p-2 font-bold shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] outline-none"
        />
      </div>

      <div className="md:w-5/12">
        <label htmlFor="starts_before" className="font-bold block mb-1">
          Session starts before
        </label>
        <input
          type="date"
          id="starts_before"
          name="starts_before"
          value={form.starts_before}
          onChange={handleChange}
          className="w-full rounded-md border-2 border-black p-2 font-bold shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] outline-none"
        />
      </div>

      <div className="md:w-full flex justify-center mt-6">
        <button
          type="submit"
          className="flex cursor-pointer items-center justify-center rounded-md border-2 border-black bg-purple px-10 py-3 font-bold shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] transition-all hover:translate-x-[3px] hover:translate-y-[3px] hover:shadow-none"
        >
          Go
        </button>
      </div>
    </form>
  );
}
