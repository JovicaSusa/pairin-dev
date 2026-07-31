import { Form } from "@inertiajs/react";
import { ArrowRight } from "lucide-react";
import { formatShort } from "@/helpers/date";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarImage, AvatarFallback } from "@/components/ui/avatar";

export default function SessionCard({ session }) {
  return (
    <div className="mb-6 rounded-2xl border-2 border-black bg-white p-5 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] md:p-6">
      <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div className="flex items-center gap-3">
          <Avatar className="h-11 w-11 border-2 border-black">
            <AvatarImage src={session.other_participant.image_url} alt={session.other_participant.name} />
            <AvatarFallback className="bg-orange text-white font-bold">{session.other_participant.name?.[0]}</AvatarFallback>
          </Avatar>
          <div>
            <p className="font-bold text-sm">{session.other_participant.name}</p>
            <span className="text-xs text-black/50">
              {session.other_participant.profession}
              {session.other_participant.profession && " · "}
              {session.other_participant.level}
            </span>
          </div>
        </div>

        <div className="flex items-center gap-1.5">
          <Badge variant="neutral" className="rounded-full text-xs">
            {formatShort(session.start_at)}
          </Badge>
          <ArrowRight className="h-3 w-3 shrink-0 text-black/30" />
          <Badge variant="neutral" className="rounded-full text-xs">
            {formatShort(session.end_at)}
          </Badge>
        </div>
      </div>

      <div className="mt-5 border-t-2 border-black/10 pt-4">
        {session.is_holder ? (
          <Form method="patch" action={`/sessions/${session.id}`} className="flex flex-col items-stretch gap-2 md:flex-row md:items-end">
            {({ processing }) => (
              <>
                <div className="flex flex-1 flex-col">
                  <Label htmlFor="session_call_link" className="mb-1">Call link</Label>
                  <Input id="session_call_link" name="call_link" defaultValue={session.call_link || ""} />
                </div>

                <Button type="submit" disabled={processing} className="md:w-32">
                  {processing ? "..." : "Add"}
                </Button>
              </>
            )}
          </Form>
        ) : (
          session.call_link ? (
            <Button asChild className="w-full">
              <a href={session.call_link} rel="noopener noreferrer" target="_blank">
                Join Call
              </a>
            </Button>
          ) : (
            <p className="text-sm font-semibold text-black/50">
              Waiting for {session.holder_name} to provide the link
            </p>
          )
        )}
      </div>
    </div>
  )
}
