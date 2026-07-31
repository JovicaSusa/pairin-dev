import { Head, Form } from "@inertiajs/react";
import { Collapsible, CollapsibleTrigger, CollapsibleContent } from "@/components/ui/collapsible";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Avatar, AvatarImage, AvatarFallback } from "@/components/ui/avatar";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { DatePicker } from "@/components/ui/date-picker";
import { Progress } from "@/components/ui/progress";

export default function Profile({ user, countries, languages, levels }) {
  const [previewUrl, setPreviewUrl] = useState(user.image_url);
  const [country, setCountry] = useState(user.country || "");
  const [language, setLanguage] = useState(user.language || "");
  const [level, setLevel] = useState(user.level || "");
  const [programmingSince, setProgrammingSince] = useState(
    user.programming_since ? String(user.programming_since) : ""
  );
  const [dateOfBirth, setDateOfBirth] = useState(
    user.date_of_birth ? user.date_of_birth.split("T")[0] : ""
  );

  const currentYear = new Date().getFullYear();
  const programmingYears = Array.from({ length: 51 }, (_, i) => currentYear - i);

  const handleFileChange = (e) => {
    const file = e.target.files[0];
    if (file) setPreviewUrl(URL.createObjectURL(file));
  };

  return (
    <div className="mx-auto w-full max-w-2xl px-4 pb-16 md:px-8">
      <Head title={`${user.name}'s Profile`} />

      <Form method="patch" action={`/profiles/${user.id}`}>
        {({ errors, processing, progress }) => (
          <>
            <div className="flex flex-col items-center pb-10 pt-10 text-center md:pt-14">
              <Avatar className="h-28 w-28 rounded-2xl border-2 border-black shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]">
                <AvatarImage src={previewUrl} alt={user.name} className="object-cover" />
                <AvatarFallback className="rounded-2xl bg-orange text-3xl font-bold text-white">
                  {user.name?.[0]}
                </AvatarFallback>
              </Avatar>

              <h1 className="mt-4 text-3xl">{user.name || "Your profile"}</h1>
              {user.profession && <p className="mt-1 text-black/50">{user.profession}</p>}

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
                        className="w-full rounded-xl border-2 border-black bg-white p-2 font-bold shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
                      />
                    </div>
                  </CollapsibleContent>
                </Collapsible>
              </div>
            </div>

            <div className="flex flex-col gap-6 border-t-2 border-black/10 pt-8">
              {progress && (
                <Progress value={progress.percentage ?? 0} className="w-full" />
              )}

              <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
                <div>
                  <Label className="block mb-1">Name</Label>
                  <Input name="name" defaultValue={user.name || ""} />
                  {errors.name && <div className="text-red font-bold mt-1 text-sm">{errors.name}</div>}
                </div>

                <div>
                  <Label className="block mb-1">Profession</Label>
                  <Input name="profession" defaultValue={user.profession || ""} />
                </div>
              </div>

              <div>
                <Label className="block mb-1">About</Label>
                <Textarea name="about" rows="4" defaultValue={user.about || ""} />
              </div>

              <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
                <div>
                  <Label className="block mb-1">Date of Birth</Label>
                  <input type="hidden" name="date_of_birth" value={dateOfBirth} />
                  <DatePicker
                    value={dateOfBirth}
                    onChange={setDateOfBirth}
                    placeholder="Pick your birth date"
                    captionLayout="dropdown-buttons"
                    fromYear={currentYear - 100}
                    toYear={currentYear}
                    defaultMonth={new Date(1995, 0)}
                    disabled={(date) => date > new Date()}
                  />
                </div>

                <div>
                  <Label className="block mb-1">Programming Since</Label>
                  <input type="hidden" name="programming_since" value={programmingSince} />
                  <Select value={programmingSince} onValueChange={setProgrammingSince}>
                    <SelectTrigger className="w-full">
                      <SelectValue placeholder="Select a year" />
                    </SelectTrigger>
                    <SelectContent>
                      {programmingYears.map((year) => (
                        <SelectItem key={year} value={String(year)}>{year}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </div>

              <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
                <div>
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

                <div>
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

                <div>
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

              <div className="flex justify-center pt-6">
                <Button type="submit" size="lg" disabled={processing}>
                  {processing ? "Saving..." : "Save Changes"}
                </Button>
              </div>
            </div>
          </>
        )}
      </Form>
    </div>
  );
}
