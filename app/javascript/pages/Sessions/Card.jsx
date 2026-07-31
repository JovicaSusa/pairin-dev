import { Form } from "@inertiajs/react";
import { formatShort } from "@/helpers/date";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarImage, AvatarFallback } from "@/components/ui/avatar";
import { Card, CardHeader, CardTitle, CardContent, CardFooter } from "@/components/ui/card";

export default function SessionCard({ session }) {
  return (
    <Card className="mb-12 bg-white gap-0 py-0 pb-4">
      <CardHeader className="border-b-2 border-border bg-main py-4 px-2 rounded-t-base">
        <CardTitle className="text-xl">{session.subject}</CardTitle>
      </CardHeader>

      <CardContent className="md:flex items-center max-h-fit px-2 py-4">
        <div className="md:w-1/2 flex flex-col md:flex-row items-center md:items-start gap-y-2 md:gap-x-2 text-center md:text-left">
          <Avatar className="w-12 h-12">
            <AvatarImage src={session.other_participant.image_url} alt={session.other_participant.name} />
            <AvatarFallback>{session.other_participant.name?.[0]}</AvatarFallback>
          </Avatar>
          <div>
            <p className="font-bold">{session.other_participant.name}</p>
            <span className="text-sm">
              {session.other_participant.profession}
              <span className="text-gray-400 font-black"> &bull; </span>
              {session.other_participant.level}
            </span>
          </div>
        </div>

        <div className="w-full mt-6 md:mt-0 md:w-1/2">
          <div className="w-full flex items-center justify-center md:justify-end gap-x-1">
            <Badge variant="neutral" className="text-sm px-3">
              {formatShort(session.start_at)}
            </Badge>
            <span className="block font-bold">:</span>
            <Badge variant="neutral" className="text-sm px-3">
              {formatShort(session.end_at)}
            </Badge>
          </div>
        </div>
      </CardContent>

      <CardFooter className="w-full flex justify-center px-2">
        {session.is_holder ? (
          <Form method="patch" action={`/sessions/${session.id}`} className="flex flex-col md:flex-row w-full gap-y-4 md:gap-x-2 items-center md:items-end justify-between">
            {({ processing }) => (
              <>
                <div className="flex flex-col justify-end w-full">
                  <Label htmlFor="session_call_link" className="mb-1">Call link</Label>
                  <Input id="session_call_link" name="call_link" defaultValue={session.call_link || ""} />
                </div>

                <Button type="submit" disabled={processing} className="w-3/4 md:w-1/4">
                  {processing ? "..." : "Add"}
                </Button>
              </>
            )}
          </Form>
        ) : (
          session.call_link ? (
            <Button asChild className="w-3/4 truncate">
              <a href={session.call_link} rel="noopener noreferrer" target="_blank">
                Join Call
              </a>
            </Button>
          ) : (
            <p className="font-semibold text-gray-600">
              Waiting for {session.holder_name} to provide the link
            </p>
          )
        )}
      </CardFooter>
    </Card>
  )
}
