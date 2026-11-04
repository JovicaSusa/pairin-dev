import { useState } from "react";
import { Button } from "@/components/ui/button";
import PageHeader from "@/components/PageHeader";
import EmptyState from "@/components/EmptyState";
import FilterForm from "@/components/FilterForm";
import Card from "./Card";
import { Head, router, usePage, InfiniteScroll } from "@inertiajs/react";
import { SlidersHorizontal, SearchX } from "lucide-react";

export default function Index({ pairRequests, filterOptions, filters, timezone }) {
  const { auth } = usePage().props;
  const currentUser = auth.user;

  const { tags, commitments, userLevels, languages } = filterOptions;
  const [filtersOpen, setFiltersOpen] = useState(false);

  return (
    <div className="mx-auto w-full max-w-6xl px-4 pb-16 md:px-8">
      <Head title="Partner searches" />

      <PageHeader
        eyebrow="Search"
        title="Partner searches"
        description="Find someone to learn with, talk first, then decide."
        action={
          <Button variant="neutral" size="sm" className="lg:hidden" aria-expanded={filtersOpen} onClick={() => setFiltersOpen(!filtersOpen)}>
            <SlidersHorizontal className="h-4 w-4" />
            Filters
          </Button>
        }
      />

      <div className="grid grid-cols-1 items-start gap-6 lg:grid-cols-[280px_minmax(0,1fr)]">
      <aside className={`rounded-2xl border-2 border-black bg-white p-5 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] lg:block ${filtersOpen ? "" : "hidden"}`}>
        <FilterForm
          tags={tags}
          commitments={commitments}
          userLevels={userLevels}
          languages={languages}
          filters={filters}
          onSubmit={(q) => {
            router.get("/pair_requests", { q });
          }}
        />
      </aside>

      <div className="relative flex min-w-0 flex-col gap-6">
        <InfiniteScroll
          data="pairRequests"
          loading={() => (
            <div className="flex justify-center py-8 font-bold text-black/50">Loading more...</div>
          )}
          next={({ hasMore }) =>
            !hasMore && pairRequests.length > 0 ? (
              <div className="flex justify-center py-8 text-black/40">No more partner searches</div>
            ) : null
          }
        >
          {pairRequests.map((req) => (
            <Card key={req.id} pairRequest={req} currentUserId={currentUser.id} timezone={timezone} />
          ))}
        </InfiniteScroll>

        {pairRequests.length === 0 && (
          <EmptyState
            icon={SearchX}
            title="No partner searches match your filters"
            description="Try widening your filters or check back soon. New partner searches come in all the time."
          />
        )}
      </div>
      </div>
    </div>
  );
}
