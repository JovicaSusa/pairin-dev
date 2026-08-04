import PageHeader from "@/components/PageHeader";
import EmptyState from "@/components/EmptyState";
import Card from "./Card";
import { Head, InfiniteScroll } from "@inertiajs/react";
import { BookOpen } from "lucide-react";

export default function Index({ sessionSummaries, sessionSummariesCount }) {
  return (
    <div className="mx-auto w-full max-w-3xl px-4 pb-16 md:px-8">
      <Head title="Session Summaries" />

      <PageHeader
        eyebrow="Knowledge base"
        title="Session Summaries"
        description="Browse retros from completed pairing sessions across the community."
      />

      <div className="relative mt-8 flex flex-col gap-6">
        <InfiniteScroll
          data="sessionSummaries"
          loading={() => (
            <div className="flex justify-center py-8 font-bold text-black/50">Loading more...</div>
          )}
          next={({ hasMore }) =>
            !hasMore && sessionSummaries.length > 0 ? (
              <div className="flex justify-center py-8 text-black/40">No more summaries</div>
            ) : null
          }
        >
          {sessionSummaries.map((summary) => (
            <Card key={summary.id} sessionSummary={summary} />
          ))}
        </InfiniteScroll>

        {sessionSummariesCount === 0 && (
          <EmptyState
            icon={BookOpen}
            title="No session summaries yet"
            description="Once sessions wrap up and retros come in, they'll show up here."
          />
        )}
      </div>
    </div>
  );
}
