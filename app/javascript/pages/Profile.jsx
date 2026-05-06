import { Head, useForm } from "@inertiajs/react";
import Reveal from "@/components/Reveal"
import { useState } from "react";

export default function Show({ user, countries, languages, levels }) {
  const { data, setData, patch, errors, processing } = useForm({
    name: user.name || "",
    profession: user.profession || "",
    about: user.about || "",
    date_of_birth: user.date_of_birth ? user.date_of_birth.split("T")[0] : "1995-01-01",
    programming_since: user.programming_since ? user.programming_since.split("T")[0] : "2015-01-01",
    language: user.language || "",
    country: user.country || "",
    level: user.level || "",
    image: null
  });

  const [previewUrl, setPreviewUrl] = useState(user.image_url);

  const handleFileChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      setData("image", file);
      setPreviewUrl(URL.createObjectURL(file));
    }
  }

  const handleSubmit = (e) => {
    e.preventDefault();
    patch(`/profiles/${user.id}`, {
      forceFormData: true,
    });
  }

  return (
    <div className="flex flex-col items-center w-full px-4">
      <Head title={`${user.name}'s Profile`}/>

      <div className="w-full md:w-3/4 xl:w-4/6 2xl:w-1/2">
        
        <div className="flex flex-col items-center w-full mt-12 pb-8 border-b-4 border-black border-dashed text-center">
          <h3 className="text-5xl font-bold mb-4">{user.name}</h3>
          
          <div className="w-32 h-32 border-black border-4 rounded-xl shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] overflow-hidden bg-white">
            {previewUrl ? (
              <img src={previewUrl} alt={data.name} className="w-full h-full object-contain" />
            ) : (
              <div className="w-full h-full bg-gray-200" />
            )}
          </div>
          <div className="mt-4">
            <Reveal
              key={user.image_url}
              button={
                <button className="border-2 border-black rounded-xl px-2 font-bold hover:bg-gray-100 transition-colors">
                  Change Avatar
                </button>
              }
            >
              <div className="mt-4">
                <input
                  type="file"
                  onChange={handleFileChange}
                  className="w-full rounded-md border-2 border-black p-2 font-bold shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] bg-white"
                />
              </div>
            </Reveal>             
          </div>
        </div>

        <form onSubmit={handleSubmit} className="flex flex-col items-center mt-8 pb-20">
          <div className="w-full flex flex-wrap md:flex-nowrap gap-4">
            <div className="w-full md:w-1/2 text-left">
              <label className="block font-bold mb-1">Name</label>
              <input 
                value={data.name}
                onChange={e => setData("name", e.target.value)}
                className="w-full rounded-md border-2 border-black p-[10px] font-bold shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] outline-none focus:translate-x-[3px] focus:translate-y-[3px] focus:shadow-none"
              />
              {errors.name && <div className="text-red-500 font-bold mt-1 text-sm">{errors.name}</div>}
            </div>

            <div className="w-full md:w-1/2 text-left">
              <label className="block font-bold mb-1">Profession</label>
              <input
                value={data.profession}
                onChange={e => setData("profession", e.target.value)}
                className="w-full rounded-md border-2 border-black p-[10px] font-bold shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] outline-none focus:translate-x-[3px] focus:translate-y-[3px] focus:shadow-none"
              />
            </div>
          </div>

          <div className="w-full mt-6 text-left">
            <label className="block font-bold mb-1">About</label>
            <textarea 
              rows="4"
              value={data.about} 
              onChange={e => setData("about", e.target.value)}
              className="w-full rounded-md border-2 border-black p-[10px] font-bold shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] outline-none focus:translate-x-[3px] focus:translate-y-[3px] focus:shadow-none"
            />
          </div>

          <div className="w-full flex flex-wrap md:flex-nowrap gap-4 mt-6">
            <div className="w-full md:w-1/2 text-left">
              <label className="block font-bold mb-1">Date of Birth</label>
              <input
                type="date"
                max={new Date().toISOString().split("T")[0]}
                value={data.date_of_birth}
                onChange={e => setData("date_of_birth", e.target.value)}
                className="w-full rounded-md border-2 border-black p-[10px] font-bold shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] outline-none focus:translate-x-[3px] focus:translate-y-[3px] focus:shadow-none"
              />
            </div>

            <div className="w-full md:w-1/2 text-left">
              <label className="block font-bold mb-1">Programming Since</label>
              <input
                type="date"
                max={new Date().toISOString().split("T")[0]}
                value={data.programming_since}
                onChange={e => setData("programming_since", e.target.value)}
                className="w-full rounded-md border-2 border-black p-[10px] font-bold shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] outline-none focus:translate-x-[3px] focus:translate-y-[3px] focus:shadow-none"
              />
            </div>            
          </div>

          <div className="w-full flex flex-wrap md:flex-nowrap gap-4 mt-6">
            <div className="w-full md:w-1/3 text-left">
              <label className="block font-bold mb-1">Country</label>
              <select
                value={data.country}
                onChange={e => setData("country", e.target.value)}
                className="w-full rounded-md border-2 border-black p-[10px] font-bold shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] outline-none focus:translate-x-[3px] focus:translate-y-[3px] focus:shadow-none"
              >
                <option value="">Select a country</option>
                {countries.map(([label, value]) => (
                  <option key={value} value={value}>
                    {label}
                  </option>
                ))}
              </select>
            </div>

            <div className="w-full md:w-1/3 text-left">
              <label className="block font-bold mb-1">Language</label>
              <select
                value={data.language}
                onChange={e => setData("language", e.target.value)}
                className="w-full rounded-md border-2 border-black p-[10px] font-bold shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] outline-none focus:translate-x-[3px] focus:translate-y-[3px] focus:shadow-none"
              >
                <option value="">Select a language</option>
                {languages.map(([label, value]) => (
                  <option key={value} value={value}>
                    {label}
                  </option>
                ))}
              </select>
            </div>

            <div className="w-full md:w-1/3 text-left">
              <label className="block font-bold mb-1">Level</label>
              <select
                value={data.level}
                onChange={e => setData("level", e.target.value)}
                className="w-full rounded-md border-2 border-black p-[10px] font-bold shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] outline-none focus:translate-x-[3px] focus:translate-y-[3px] focus:shadow-none"
              >
                <option value="">Select a level</option>
                {levels.map(([label, value]) => (
                  <option key={value} value={value}>
                    {label}
                  </option>
                ))}
              </select>
            </div>
          </div>

          <button
            type="submit"
            disabled={processing}
            className="mt-16 flex cursor-pointer items-center rounded-md border-2 border-black bg-purple px-10 py-3 font-bold shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] transition-all hover:translate-x-[3px] hover:translate-y-[3px] hover:shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
          >
            {processing ? "Saving..." : "Save Changes"}
          </button>
        </form>
      </div>
    </div>
  )
}
