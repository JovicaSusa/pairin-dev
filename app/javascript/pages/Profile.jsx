import { Head, Form } from "@inertiajs/react";
import Reveal from "@/components/Reveal";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Avatar, AvatarImage, AvatarFallback } from "@/components/ui/avatar";

export default function Profile({ user, countries, languages, levels }) {
  const [previewUrl, setPreviewUrl] = useState(user.image_url);

  const handleFileChange = (e) => {
    const file = e.target.files[0];
    if (file) setPreviewUrl(URL.createObjectURL(file));
  };

  return (
    <div className="flex flex-col items-center w-full px-4">
      <Head title={`${user.name}'s Profile`} />

      <div className="w-full md:w-3/4 xl:w-4/6 2xl:w-1/2">
        <Form method="patch" action={`/profiles/${user.id}`}>
          {({ errors, processing, progress }) => (
            <>
              <div className="flex flex-col items-center w-full mt-12 pb-8 border-b-4 border-black border-dashed text-center">
                <h3 className="text-5xl font-bold mb-4">{user.name}</h3>

                <Avatar className="w-32 h-32 rounded-xl border-4 border-black shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]">
                  <AvatarImage src={previewUrl} alt={user.name} className="object-contain" />
                  <AvatarFallback className="rounded-xl text-4xl">{user.name?.[0]}</AvatarFallback>
                </Avatar>

                <div className="mt-4">
                  <Reveal
                    key={user.image_url}
                    button={
                      <Button type="button" variant="neutral" size="sm">
                        Change Avatar
                      </Button>
                    }
                  >
                    <div className="mt-4">
                      <input
                        type="file"
                        name="image"
                        onChange={handleFileChange}
                        className="w-full rounded-md border-2 border-black p-2 font-bold shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] bg-white"
                      />
                    </div>
                  </Reveal>
                </div>
              </div>

              <div className="flex flex-col items-center mt-8 pb-20">
                {progress && (
                  <progress value={progress.percentage ?? 0} max="100" className="w-full mb-4" />
                )}

                <div className="w-full flex flex-wrap md:flex-nowrap gap-4">
                  <div className="w-full md:w-1/2 text-left">
                    <Label className="block mb-1">Name</Label>
                    <Input name="name" defaultValue={user.name || ""} />
                    {errors.name && <div className="text-red-500 font-bold mt-1 text-sm">{errors.name}</div>}
                  </div>

                  <div className="w-full md:w-1/2 text-left">
                    <Label className="block mb-1">Profession</Label>
                    <Input name="profession" defaultValue={user.profession || ""} />
                  </div>
                </div>

                <div className="w-full mt-6 text-left">
                  <Label className="block mb-1">About</Label>
                  <Textarea name="about" rows="4" defaultValue={user.about || ""} />
                </div>

                <div className="w-full flex flex-wrap md:flex-nowrap gap-4 mt-6">
                  <div className="w-full md:w-1/2 text-left">
                    <Label className="block mb-1">Date of Birth</Label>
                    <Input
                      type="date"
                      name="date_of_birth"
                      max={new Date().toISOString().split("T")[0]}
                      defaultValue={user.date_of_birth ? user.date_of_birth.split("T")[0] : "1995-01-01"}
                    />
                  </div>

                  <div className="w-full md:w-1/2 text-left">
                    <Label className="block mb-1">Programming Since</Label>
                    <Input
                      type="date"
                      name="programming_since"
                      max={new Date().toISOString().split("T")[0]}
                      defaultValue={user.programming_since ? user.programming_since.split("T")[0] : "2015-01-01"}
                    />
                  </div>
                </div>

                <div className="w-full flex flex-wrap md:flex-nowrap gap-4 mt-6">
                  <div className="w-full md:w-1/3 text-left">
                    <Label className="block mb-1">Country</Label>
                    <select
                      name="country"
                      defaultValue={user.country || ""}
                      className="w-full rounded-md border-2 border-black p-[10px] font-bold shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] outline-none focus:translate-x-[3px] focus:translate-y-[3px] focus:shadow-none"
                    >
                      <option value="">Select a country</option>
                      {countries.map(([label, value]) => (
                        <option key={value} value={value}>{label}</option>
                      ))}
                    </select>
                  </div>

                  <div className="w-full md:w-1/3 text-left">
                    <Label className="block mb-1">Language</Label>
                    <select
                      name="language"
                      defaultValue={user.language || ""}
                      className="w-full rounded-md border-2 border-black p-[10px] font-bold shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] outline-none focus:translate-x-[3px] focus:translate-y-[3px] focus:shadow-none"
                    >
                      <option value="">Select a language</option>
                      {languages.map(([label, value]) => (
                        <option key={value} value={value}>{label}</option>
                      ))}
                    </select>
                  </div>

                  <div className="w-full md:w-1/3 text-left">
                    <Label className="block mb-1">Level</Label>
                    <select
                      name="level"
                      defaultValue={user.level || ""}
                      className="w-full rounded-md border-2 border-black p-[10px] font-bold shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] outline-none focus:translate-x-[3px] focus:translate-y-[3px] focus:shadow-none"
                    >
                      <option value="">Select a level</option>
                      {levels.map(([label, value]) => (
                        <option key={value} value={value}>{label}</option>
                      ))}
                    </select>
                  </div>
                </div>

                <Button type="submit" size="lg" disabled={processing} className="mt-16">
                  {processing ? "Saving..." : "Save Changes"}
                </Button>
              </div>
            </>
          )}
        </Form>
      </div>
    </div>
  );
}
