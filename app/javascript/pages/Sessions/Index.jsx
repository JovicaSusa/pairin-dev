import { Head } from "@inertiajs/react";
import { CalendarClock } from "lucide-react";
import PageHeader from "@/components/PageHeader";
import EmptyState from "@/components/EmptyState";
import Card from "./Card";

export default function Index( {sessions} ) {
  return (
    <div className="mx-auto w-full max-w-3xl px-4 pb-16 md:px-8">
      <Head title="Your Sessions" />

      <PageHeader eyebrow="Sessions" title="Sessions" description="Your upcoming and past pairing sessions." />

      {sessions.length > 0 ? (
        sessions.map((session) => (
          <Card key={session.id} session={session} />
        ))
      ) : (
        <EmptyState icon={CalendarClock} title="No upcoming sessions found" description="Once a request is matched, your sessions will show up here." />
      )}
    </div>
  )
}
