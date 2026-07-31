import { Form, Head } from '@inertiajs/react';
import { formatShort } from "@/helpers/date";
import { useState } from "react";
import PageHeader from "@/components/PageHeader";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";

export default function New({ pairRequestId, periods }) {
  const [periodId, setPeriodId] = useState(String(periods[0]?.id || ""));

  return (
    <div className="mx-auto w-full max-w-2xl px-4 pb-16 md:px-8">
      <Head title="Send application" />

      <PageHeader eyebrow="Apply" title="Send application" description="Introduce yourself and pick the time slot that works for you." />

      <Form method="post" action={`/pair_requests/${pairRequestId}/offers`} className="flex flex-col items-stretch">
        {({ errors, processing }) => (
          <>
            <div className="w-full">
              <Label htmlFor="message" className="block mb-1">Message</Label>
              <Textarea id="message" name="message" rows="4" className="w-full" />
              {errors.message && (
                <div className="text-red font-bold mt-1 text-sm">{errors.message}</div>
              )}
            </div>

            <div className="w-full mt-4">
              <Label className="block mb-1">Select period</Label>
              <input type="hidden" name="period_id" value={periodId} />
              <Select value={periodId} onValueChange={setPeriodId}>
                <SelectTrigger className="w-full">
                  <SelectValue placeholder="Select a period" />
                </SelectTrigger>
                <SelectContent>
                  {periods.map(period => (
                    <SelectItem key={period.id} value={String(period.id)}>
                      {formatShort(period.start_at)} : {formatShort(period.end_at)}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              {(errors.period || errors.period_id) && (
                <div className="text-red font-bold mt-1 text-sm">{errors.period || errors.period_id}</div>
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
