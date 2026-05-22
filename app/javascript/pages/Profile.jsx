import { Head, Form } from "@inertiajs/react";
import { Collapsible, CollapsibleTrigger, CollapsibleContent } from "@/components/ui/collapsible";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Avatar, AvatarImage, AvatarFallback } from "@/components/ui/avatar";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";

export default function Profile({ user, countries, languages, levels }) {
  const [previewUrl, setPreviewUrl] = useState(user.image_url);
  const [country, setCountry] = useState(user.country || "");
  const [language, setLanguage] = useState(user.language || "");
  const [level, setLevel] = useState(user.level || "");

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
                  <Collapsible key={user.image_url}>
                    <CollapsibleTrigger asChild>
                      <Button type="button" variant="neutral" size="sm">
                        Change Avatar
                      </Button>
                    </CollapsibleTrigger>
                    <CollapsibleContent>
                      <div className="mt-4">
                        <input
                          type="file"
                          name="image"
                          onChange={handleFileChange}
                          className="w-full rounded-md border-2 border-black p-2 font-bold shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] bg-white"
                        />
                      </div>
                    </CollapsibleContent>
                  </Collapsible>
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
                    <input type="hidden" name="country" value={country} />
                    <Select value={country} onValueChange={setCountry}>
                      <SelectTrigger className="w-full">
                        <SelectValue placeholder="Select a country" />
                      </SelectTrigger>
                      <SelectContent>
                        {countries.map(([label, value]) => (
                          <SelectItem key={value} value={value}>{label}</SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>

                  <div className="w-full md:w-1/3 text-left">
                    <Label className="block mb-1">Language</Label>
                    <input type="hidden" name="language" value={language} />
                    <Select value={language} onValueChange={setLanguage}>
                      <SelectTrigger className="w-full">
                        <SelectValue placeholder="Select a language" />
                      </SelectTrigger>
                      <SelectContent>
                        {languages.map(([label, value]) => (
                          <SelectItem key={value} value={value}>{label}</SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>

                  <div className="w-full md:w-1/3 text-left">
                    <Label className="block mb-1">Level</Label>
                    <input type="hidden" name="level" value={level} />
                    <Select value={level} onValueChange={setLevel}>
                      <SelectTrigger className="w-full">
                        <SelectValue placeholder="Select a level" />
                      </SelectTrigger>
                      <SelectContent>
                        {levels.map(([label, value]) => (
                          <SelectItem key={value} value={value}>{label}</SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
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
