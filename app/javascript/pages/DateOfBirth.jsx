import { Head, useForm } from "@inertiajs/react";
import PageHeader from "@/components/PageHeader";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

export default function DateOfBirth() {
  const { data, setData, patch, processing, errors } = useForm({ date_of_birth: "" });

  const submit = (e) => {
    e.preventDefault();
    patch("/date_of_birth");
  };

  return (
    <div className="mx-auto w-full max-w-md px-4 pb-16 md:px-8">
      <Head title="Your date of birth" />

      <PageHeader eyebrow="One quick thing" title="Your date of birth" description="We need this once to keep your account going." />

      <form onSubmit={submit} className="flex flex-col gap-4">
        <div>
          <Label htmlFor="date_of_birth" className="mb-1 block">Date of birth</Label>
          <Input id="date_of_birth" type="date" value={data.date_of_birth} onChange={(e) => setData("date_of_birth", e.target.value)} />
          {errors.date_of_birth && <div className="mt-1 text-sm font-bold text-red">{errors.date_of_birth}</div>}
        </div>

        <Button type="submit" size="lg" disabled={processing}>{processing ? "Saving..." : "Continue"}</Button>
      </form>
    </div>
  );
}
