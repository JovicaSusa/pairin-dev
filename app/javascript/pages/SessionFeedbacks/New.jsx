import { Form, Head } from '@inertiajs/react';
import { useState } from "react";
import PageHeader from "@/components/PageHeader";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";

const WENT_WELL_EMOJI = {
  great: "🎉",
  good: "🙂",
  okay: "😐",
  tough: "😓"
};

const humanize = (value) => value.charAt(0).toUpperCase() + value.slice(1);

export default function New({ sessionId, subject, otherParticipantName, wentWellValues }) {
  const [wentWell, setWentWell] = useState("");

  return (
    <div className="mx-auto w-full max-w-2xl px-4 pb-16 md:px-8">
      <Head title="Session retro" />

      <PageHeader
        eyebrow="Retro"
        title={subject || "How did it go?"}
        description={otherParticipantName ? `Share a private retro on your session with ${otherParticipantName}. Only you and your partner can see this.` : "Share a private retro on this session."}
      />

      <Form method="post" action="/session_feedbacks" className="flex flex-col items-stretch">
        {({ errors, processing }) => (
          <>
            <input type="hidden" name="session_id" value={sessionId} />

            {errors.participant_id && (
              <div className="mb-4 rounded-xl border-2 border-black bg-orange/10 p-3 text-sm font-bold">
                You've already submitted feedback for this session.
              </div>
            )}

            <div className="w-full">
              <Label className="block mb-1">How did it go?</Label>
              <input type="hidden" name="went_well" value={wentWell} />
              <div className="flex flex-wrap gap-2" role="radiogroup" aria-label="How did it go?">
                {wentWellValues.map((value) => (
                  <Button
                    key={value}
                    type="button"
                    role="radio"
                    aria-checked={wentWell === value}
                    variant={wentWell === value ? "default" : "neutral"}
                    onClick={() => setWentWell(value)}
                  >
                    <span className="mr-1.5">{WENT_WELL_EMOJI[value]}</span>
                    {humanize(value)}
                  </Button>
                ))}
              </div>
              {errors.went_well && (
                <div className="text-red font-bold mt-1 text-sm">{errors.went_well}</div>
              )}
            </div>

            <div className="w-full mt-4">
              <Label htmlFor="learned" className="block mb-1">What did you learn?</Label>
              <Textarea id="learned" name="learned" rows="4" className="w-full" />
              {errors.learned && (
                <div className="text-red font-bold mt-1 text-sm">{errors.learned}</div>
              )}
            </div>

            <div className="w-full mt-4">
              <Label htmlFor="notes" className="block mb-1">Notes</Label>
              <Textarea id="notes" name="notes" rows="4" className="w-full" />
              {errors.notes && (
                <div className="text-red font-bold mt-1 text-sm">{errors.notes}</div>
              )}
            </div>

            <div className="w-full mt-4">
              <Label htmlFor="code_snippet" className="block mb-1">
                Code <span className="text-xs font-normal">(paste a GitHub link or a snippet, optional)</span>
              </Label>
              <Textarea id="code_snippet" name="code_snippet" rows="4" className="w-full" />
              {errors.code_snippet && (
                <div className="text-red font-bold mt-1 text-sm">{errors.code_snippet}</div>
              )}
            </div>

            <div className="w-full mt-4">
              <Label htmlFor="code_snippet_language" className="block mb-1">
                Code language <span className="text-xs font-normal">(optional)</span>
              </Label>
              <Input id="code_snippet_language" name="code_snippet_language" className="w-full" />
              {errors.code_snippet_language && (
                <div className="text-red font-bold mt-1 text-sm">{errors.code_snippet_language}</div>
              )}
            </div>

            <Button type="submit" size="lg" disabled={processing} className="mt-10 self-center">
              {processing ? "Sending..." : "Submit retro"}
            </Button>
          </>
        )}
      </Form>
    </div>
  );
}
