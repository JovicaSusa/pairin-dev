import { Head, Link } from "@inertiajs/react"
import { Bell, Sparkles } from "lucide-react"
import PageHeader from "@/components/PageHeader"
import EmptyState from "@/components/EmptyState"

export default function Activities({ activities }) {
  return (
    <div className="mx-auto w-full max-w-3xl px-4 pb-16 md:px-8">
      <Head title="Activity Feed"/>

      <PageHeader
        eyebrow="Feed"
        title="Activity Feed"
        description="Updates from your requests, applications, and matches, all in one place."
      />

      {activities.length > 0 ? (
        <div className="flex flex-col gap-5">
          {activities.map((activity) => (
            <div
              key={activity.id}
              className="flex gap-4 rounded-2xl border-2 border-black bg-white p-5 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
            >
              <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl border-2 border-black bg-purple/10">
                <Bell className="h-5 w-5 text-purple" strokeWidth={2.25} />
              </div>
              <div className="min-w-0">
                <p className="font-bold">{activity.title}</p>
                <p className="mt-1 text-black/60">{activity.content}</p>
              </div>
            </div>
          ))}
        </div>
      ) : (
        <EmptyState icon={Sparkles} title="Nothing new from the community yet">
          <p className="mt-1 text-black/50">
            Start by{" "}
            <Link href="/users/pair_requests/new" className="font-bold text-purple underline">
              creating a pair request
            </Link>{" "}
            or{" "}
            <Link href="/pair_requests" className="font-bold text-purple underline">
              sending an offer
            </Link>
            .
          </p>
        </EmptyState>
      )}
    </div>
  )
}
