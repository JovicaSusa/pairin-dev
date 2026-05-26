import { Collapsible, CollapsibleTrigger, CollapsibleContent } from "@/components/ui/collapsible";
import FilterForm from "@/components/FilterForm";
import Card from "./Card";
import { Head, router, usePage, InfiniteScroll } from "@inertiajs/react";
import preferencesImg from "@/assets/images/preferences.svg";

export default function Index({ pairRequests, filterOptions, filters }) {
  const { auth } = usePage().props;
  const currentUser = auth.user;

  const { tags, userLevels, languages } = filterOptions;

  return (
    <>
      <div className="flex flex-col items-center w-full">
        <Head title="Pair Programming Requests" />

        <div className="w-full md:w-3/4 xl:w-4/6 2xl:w-1/2">
          <div className="flex w-full items-center mt-12 pb-8 border-b-4 border-black border-dashed text-center">
            <h3 className="text-5xl font-bold">Pair Programming Requests</h3>
          </div>

          <div className="mt-12">
            <Collapsible>
              <CollapsibleTrigger asChild>
                <button className="relative group overflow-hidden items-center w-full flex justify-end mb-2 pr-4 md:pr-0">
                  <span className="absolute block font-bold top-0 -right-[60px] transition ease-in-out duration-500 group-hover:-translate-x-24">
                    Filter
                  </span>
                  <img src={preferencesImg} className="z-10 bg-yellow-50" />
                </button>
              </CollapsibleTrigger>
              <CollapsibleContent>
                <FilterForm
                  tags={tags}
                  userLevels={userLevels}
                  languages={languages}
                  filters={filters}
                  onSubmit={(q) => {
                    router.get("/pair_requests", { q });
                  }}
                />
              </CollapsibleContent>
            </Collapsible>
          </div>

          <div className="mt-12 mb-12">
            <InfiniteScroll
              data="pairRequests"
              loading={() => (
                <div className="flex justify-center py-8">
                  <div className="text-lg font-bold">Loading more...</div>
                </div>
              )}
              next={({ hasMore }) =>
                !hasMore && pairRequests.length > 0 ? (
                  <div className="flex justify-center py-8">
                    <div className="text-lg font-bold text-gray-500">No more requests</div>
                  </div>
                ) : null
              }
            >
              {pairRequests.map((req) => (
                <Card key={req.id} pairRequest={req} currentUserId={currentUser.id} />
              ))}
            </InfiniteScroll>
          </div>
        </div>
      </div>
    </>
  );
}
