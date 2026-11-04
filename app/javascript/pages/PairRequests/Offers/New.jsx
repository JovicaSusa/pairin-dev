import { Form, Head } from '@inertiajs/react';
import PageHeader from "@/components/PageHeader";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";

export default function New({ pairRequestId }) {
  return (
    <div className="mx-auto w-full max-w-2xl px-4 pb-16 md:px-8">
      <Head title="Send application" />

      <PageHeader eyebrow="Apply" title="Send application" description="Introduce yourself and say what you want to get out of this." />

      <Form method="post" action={`/pair_requests/${pairRequestId}/offers`} className="flex flex-col items-stretch">
        {({ errors, processing }) => (
          <>
            <div className="w-full">
              <Label htmlFor="message" className="block mb-1">Message</Label>
              <Textarea id="message" name="offer[message]" rows="4" className="w-full" />
              {errors.message && (
                <div className="text-red font-bold mt-1 text-sm">{errors.message}</div>
              )}
            </div>

            <Button type="submit" size="lg" disabled={processing} className="mt-10 self-center">
              {processing ? 'Sending...' : 'Apply'}
            </Button>
          </>
        )}
      </Form>
    </div>
  );
}
