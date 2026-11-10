import { Head, useForm } from "@inertiajs/react";
import PageHeader from "@/components/PageHeader";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

// A one-time step for accounts with no name (#262).
export default function Name() {
  const { data, setData, patch, processing, errors } = useForm({ name: "" });

  const submit = (e) => {
    e.preventDefault();
    patch("/name");
  };

  return (
    <div className="mx-auto w-full max-w-md px-4 pb-16 md:px-8">
      <Head title="Your name" />

      <PageHeader eyebrow="One quick thing" title="What should partners call you?" description="Your partners see this in chats, sessions and emails." />

      <form onSubmit={submit} className="flex flex-col gap-4">
        <div>
          <Label htmlFor="name" className="mb-1 block">Your name</Label>
          <Input id="name" autoFocus maxLength={60} autoComplete="given-name" value={data.name} onChange={(e) => setData("name", e.target.value)} />
          {errors.name && <div className="mt-1 text-sm font-bold text-red">{errors.name}</div>}
        </div>

        <Button type="submit" size="lg" disabled={processing || !data.name.trim()}>{processing ? "Saving..." : "Continue"}</Button>
      </form>
    </div>
  );
}
