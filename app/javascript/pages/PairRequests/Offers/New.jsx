import { Form, Head, Link } from '@inertiajs/react';
import { slotParts } from "@/helpers/date";
import { useMemo, useState } from "react";
import PageHeader from "@/components/PageHeader";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectGroup, SelectItem, SelectLabel, SelectTrigger, SelectValue } from "@/components/ui/select";

export default function New({ pairRequestId, slots, timezone }) {
  const [startAt, setStartAt] = useState(slots[0]?.start_at || "");

  // Slots grouped under their day, in the offerer's timezone.
  const days = useMemo(() => {
    const groups = new Map();
    slots.forEach((slot) => {
      const { day, time } = slotParts(slot.start_at, slot.end_at, timezone);
      if (!groups.has(day)) groups.set(day, []);
      groups.get(day).push({ ...slot, time });
    });
    return [...groups.entries()];
  }, [slots, timezone]);

  return (
    <div className="mx-auto w-full max-w-2xl px-4 pb-16 md:px-8">
      <Head title="Send application" />

      <PageHeader eyebrow="Apply" title="Send application" description="Introduce yourself and pick a time from the poster's weekly hours." />

      {slots.length === 0 ? (
        <p className="rounded-2xl border-2 border-black bg-white p-5">
          No open times in the next two weeks.{" "}
          <Link href="/pair_requests" className="font-bold text-purple">See other requests</Link>
        </p>
      ) : (
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

              <div className="w-full mt-4">
                <Label className="block mb-1">Pick a time</Label>
                <input type="hidden" name="offer[start_at]" value={startAt} />
                <Select value={startAt} onValueChange={setStartAt}>
                  <SelectTrigger className="w-full" aria-label="Pick a time">
                    <SelectValue placeholder="Pick a time" />
                  </SelectTrigger>
                  <SelectContent>
                    {days.map(([day, daySlots]) => (
                      <SelectGroup key={day}>
                        <SelectLabel>{day}</SelectLabel>
                        {daySlots.map((slot) => (
                          <SelectItem key={slot.start_at} value={slot.start_at}>
                            {day}, {slot.time}
                          </SelectItem>
                        ))}
                      </SelectGroup>
                    ))}
                  </SelectContent>
                </Select>
                <p className="mt-1 text-xs text-black/50">Times in {timezone}.</p>
                {errors.period && (
                  <div className="text-red font-bold mt-1 text-sm">{errors.period}</div>
                )}
              </div>

              <Button type="submit" size="lg" disabled={processing} className="mt-10 self-center">
                {processing ? 'Sending...' : 'Apply'}
              </Button>
            </>
          )}
        </Form>
      )}
    </div>
  );
}
