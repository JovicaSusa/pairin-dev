import { Head } from "@inertiajs/react";
import Card from "./Card";

export default function Index( {sessions} ) {
  return (
    <div className="flex flex-col items-center px-4">
      <Head title="Your Sessions" />

      <div className="w-full md:w-3/4 xl:w-4/6 2xl:w-1/2">
        <div className="flex w-full items-center justify-center md:justify-start mt-12 pb-8 border-b-4 border-black border-dashed text-center md:text-left">
          <h3 className="text-4xl md:text-5xl font-bold">Sessions</h3>
        </div>
        <div className="mt-12">
          {sessions.length > 0 ? (
            sessions.map((session) => (
              <Card key={session.id} session={session} />
            ))
          ) : (
            <p className="text-center font-bold text-xl">No upcoming sessions found.</p>
          )}
        </div>
      </div>
    </div>
  )
}

