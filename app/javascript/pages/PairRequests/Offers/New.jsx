import { Form, Head } from '@inertiajs/react';
import { formatShort } from "@/helpers/date";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";

export default function New({ pairRequestId, periods }) {
  const [periodId, setPeriodId] = useState(String(periods[0]?.id || ""));

  return (
    <div className="flex flex-col items-center w-full px-4">
      <Head title="Send application" />
      <div className="w-full md:w-3/4 xl:w-4/6 2xl:w-1/2">
        <div className="flex w-full items-center mt-12 pb-8 border-b-4 border-black border-dashed text-center">
          <h3 className="text-5xl font-bold">Send application</h3>
        </div>

        <Form method="post" action={`/pair_requests/${pairRequestId}/offers`} className="flex flex-col items-start mt-12">
          {({ errors, processing }) => (
            <>
              <div className="w-full">
                <Label htmlFor="message" className="block mb-1">Message</Label>
                <Textarea id="message" name="message" rows="4" className="w-full" />
                {errors.message && (
                  <div className="text-red-600 font-bold mt-1">{errors.message}</div>
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
                  <div className="text-orange font-bold mt-1">{errors.period || errors.period_id}</div>
                )}
              </div>

              <div className="w-full flex justify-center mt-12">
                <Button type="submit" size="lg" disabled={processing}>
                  {processing ? 'Sending...' : 'Apply'}
                </Button>
              </div>
            </>
          )}
        </Form>
      </div>
    </div>
  );
}
