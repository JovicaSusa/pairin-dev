import { Collapsible, CollapsibleTrigger, CollapsibleContent } from "@/components/ui/collapsible";
import { Button } from "@/components/ui/button";
import PageHeader from "@/components/PageHeader";
import EmptyState from "@/components/EmptyState";
import FilterForm from "@/components/FilterForm";
import Card from "./Card";
import { Head, router, usePage, InfiniteScroll } from "@inertiajs/react";
import { SlidersHorizontal, SearchX } from "lucide-react";

export default function Index({ pairRequests, filterOptions, filters }) {
  const { auth } = usePage().props;
  const currentUser = auth.user;

  const { tags, userLevels, languages } = filterOptions;

  return (
    <div className="mx-auto w-full max-w-3xl px-4 pb-16 md:px-8">
      <Head title="Pair Programming Requests" />

      <PageHeader
        eyebrow="Search"
        title="Pair Programming Requests"
        description="Browse open requests from the community and find a partner to build or learn with."
        action={
          <Collapsible>
            <CollapsibleTrigger asChild>
              <Button variant="neutral" size="sm">
                <SlidersHorizontal className="h-4 w-4" />
                Filters
              </Button>
            </CollapsibleTrigger>
            <CollapsibleContent className="w-full">
              <div className="fixed inset-x-4 top-24 z-40 rounded-2xl border-2 border-black bg-white p-6 shadow-[6px_6px_0px_0px_rgba(0,0,0,1)] md:absolute md:inset-x-auto md:right-0 md:top-full md:mt-3 md:w-[560px]">
                <FilterForm
                  tags={tags}
                  userLevels={userLevels}
                  languages={languages}
                  filters={filters}
                  onSubmit={(q) => {
                    router.get("/pair_requests", { q });
                  }}
                />
              </div>
            </CollapsibleContent>
          </Collapsible>
        }
      />

      <div className="relative flex flex-col gap-6">
        <InfiniteScroll
          data="pairRequests"
          loading={() => (
            <div className="flex justify-center py-8 font-bold text-black/50">Loading more...</div>
          )}
          next={({ hasMore }) =>
            !hasMore && pairRequests.length > 0 ? (
              <div className="flex justify-center py-8 text-black/40">No more requests</div>
            ) : null
          }
        >
          {pairRequests.map((req) => (
            <Card key={req.id} pairRequest={req} currentUserId={currentUser.id} />
          ))}
        </InfiniteScroll>

        {pairRequests.length === 0 && (
          <EmptyState
            icon={SearchX}
            title="No requests match your search"
            description="Try widening your filters or check back soon — new requests come in all the time."
          />
        )}
      </div>
    </div>
  );
}
