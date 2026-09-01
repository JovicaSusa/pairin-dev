import { useState } from "react";
import { Collapsible, CollapsibleTrigger, CollapsibleContent } from "@/components/ui/collapsible";
import { Tabs, TabsList, TabsTrigger, TabsContent } from "@/components/ui/tabs";
import { Button } from "@/components/ui/button";
import PageHeader from "@/components/PageHeader";
import EmptyState from "@/components/EmptyState";
import FilterForm from "@/components/FilterForm";
import Card from "./Card";
import { Head, router, usePage, InfiniteScroll } from "@inertiajs/react";
import { SlidersHorizontal, SearchX, Radio, CalendarClock } from "lucide-react";

export default function Index({ livePairRequests, scheduledPairRequests, scheduledPairRequestsCount, filterOptions, filters }) {
  const { auth } = usePage().props;
  const currentUser = auth.user;
  const [filtersOpen, setFiltersOpen] = useState(false);

  const { tags, userLevels, languages } = filterOptions;

  return (
    <div className="mx-auto w-full max-w-3xl px-4 pb-16 md:px-8">
      <Head title="Pair Programming Requests" />

      <PageHeader
        eyebrow="Search"
        title="Pair Programming Requests"
        description="Browse open requests from the community and find a partner to build or learn with."
      />

      <Tabs defaultValue={livePairRequests.length > 0 ? "live" : "scheduled"} className="mt-8">
        <Collapsible open={filtersOpen} onOpenChange={setFiltersOpen}>
          <div className="flex flex-wrap items-center justify-between gap-3">
            <TabsList>
              <TabsTrigger value="live" className="gap-2 px-4">
                <Radio className="h-4 w-4" />
                Live now
                <span className="text-xs opacity-60">{livePairRequests.length}</span>
              </TabsTrigger>
              <TabsTrigger value="scheduled" className="gap-2 px-4">
                <CalendarClock className="h-4 w-4" />
                Scheduled
                <span className="text-xs opacity-60">{scheduledPairRequestsCount}</span>
              </TabsTrigger>
            </TabsList>

            <CollapsibleTrigger asChild>
              <Button variant="neutral" size="sm">
                <SlidersHorizontal className="h-4 w-4" />
                Filters
              </Button>
            </CollapsibleTrigger>
          </div>

          <CollapsibleContent className="overflow-hidden data-[state=open]:animate-collapsible-down data-[state=closed]:animate-collapsible-up">
            <div className="mt-4 rounded-2xl border-2 border-black bg-white p-6 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]">
              <p className="mb-4 font-headline text-sm font-bold">Refine your search</p>
              <FilterForm
                tags={tags}
                userLevels={userLevels}
                languages={languages}
                filters={filters}
                onSubmit={(q) => {
                  setFiltersOpen(false);
                  router.get("/pair_requests", { q });
                }}
              />
            </div>
          </CollapsibleContent>
        </Collapsible>

        <TabsContent value="live" className="mt-6">
          {livePairRequests.length > 0 ? (
            <div className="flex flex-col gap-6">
              {livePairRequests.map((req) => (
                <Card key={req.id} pairRequest={req} currentUserId={currentUser.id} live />
              ))}
            </div>
          ) : (
            <EmptyState
              icon={Radio}
              title="No one is live right now"
              description="Check the Scheduled tab to line up a session ahead of time."
            />
          )}
        </TabsContent>

        <TabsContent value="scheduled" className="mt-6">
          <div className="relative flex flex-col gap-6">
            <InfiniteScroll
              data="scheduledPairRequests"
              loading={() => (
                <div className="flex justify-center py-8 font-bold text-black/50">Loading more...</div>
              )}
              next={({ hasMore }) =>
                !hasMore && scheduledPairRequests.length > 0 ? (
                  <div className="flex justify-center py-8 text-black/40">No more requests</div>
                ) : null
              }
            >
              {scheduledPairRequests.map((req) => (
                <Card key={req.id} pairRequest={req} currentUserId={currentUser.id} />
              ))}
            </InfiniteScroll>

            {scheduledPairRequests.length === 0 && (
              <EmptyState
                icon={SearchX}
                title="No requests match your search"
                description="Try widening your filters or check back soon — new requests come in all the time."
              />
            )}
          </div>
        </TabsContent>
      </Tabs>
    </div>
  );
}
