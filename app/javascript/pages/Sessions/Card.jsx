import { Form } from "@inertiajs/react";
import { formatShort } from "@/helpers/date";
import { Button } from "@/components/ui/button";

export default function Card({ session }) {
  return (
    <div className="mb-12 border-2 pb-4 border-black rounded-t-md bg-white shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]">
      <div className="border-b-2 border-black py-4 px-2 rounded-t-md bg-green">
        <h3 className="font-bold text-xl">{session.subject}</h3>
      </div>

      <div className="md:flex items-center max-h-fit px-2 py-4">
        <div className="md:w-1/2 flex flex-col md:flex-row items-center md:items-start gap-y-2 md:gap-x-2 text-center md:text-left">
          <figure className="border-2 border-black w-12 h-12 overflow-hidden rounded-md">
            <img src={session.other_participant.image_url} alt="" className="w-full h-full object-contain" />
          </figure>
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
            <div className="rounded-xl text-sm border-2 border-black px-3 py-0.5 font-semibold bg-white">
              {formatShort(session.start_at)}
            </div>
            <span className="block font-bold">:</span>
            <div className="rounded-xl text-sm border-2 border-black px-3 py-0.5 font-semibold bg-white">
              {formatShort(session.end_at)}
            </div>
          </div>
        </div>
      </div>

      <div className="w-full flex justify-center px-2">
        {session.is_holder ? (
          <Form method="patch" action={`/sessions/${session.id}`} className="flex flex-col md:flex-row w-full gap-y-4 md:gap-x-2 items-center md:items-end justify-between">
            {({ processing }) => (
              <>
                <div className="flex flex-col justify-end w-full">
                  <label className="font-bold">Call link</label>
                  <input
                    name="call_link"
                    defaultValue={session.call_link || ""}
                    className="w-full rounded-md border-2 border-black p-2 font-bold shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] outline-none transition-all focus:translate-x-[2px] focus:translate-y-[2px] focus:shadow-none"
                  />
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
      </div>
    </div>
  )
}
