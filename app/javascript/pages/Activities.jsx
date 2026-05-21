import { Head, Link } from "@inertiajs/react"
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card"

export default function Activities({ activities }) {
  return (
    <div className="flex flex-col items-center w-full px-4">
      <Head title="Activity Feed"/>

      <div className="w-full md:w-3/4 xl:w-4/6 2xl:w-1/2">
        <div className="flex w-full items-center justify-center md:justify-start mt-12 pb-8 border-b-4 border-black border-dashed text-center md:text-left">
          <h3 className="text-4xl md:text-5xl font-bold">Activity Feed</h3>
        </div>

        <div className="mt-12">
          {activities.length > 0 ? (
            activities.map((activity) => (
              <Card key={activity.id} className="mb-8 bg-white gap-0 py-0">
                <CardHeader className="border-b-2 border-border bg-main py-4 px-2 rounded-t-base">
                  <CardTitle>{activity.title}</CardTitle>
                </CardHeader>
                <CardContent className="px-2 py-4">
                  <p>{activity.content}</p>
                </CardContent>
              </Card>
            ))
          ) : (
            <div className="text-center p-8 border-2 border-black border-dashed rounded-md bg-white">
              <p className="mb-4">Nothing new from community for you!</p>
              <p>
                But we know how to help you, you can start by{" "}
                <Link href="/users/pair_requests/new" className="font-bold underline text-purple">
                  creating a pair request
                </Link>{" "}
                or maybe{" "}
                <Link href="/pair_requests" className="font-bold underline text-purple">
                  sending an offer
                </Link>
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
