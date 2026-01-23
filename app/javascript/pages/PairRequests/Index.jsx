import AppLayout from "@/layouts/AppLayout";
import Reveal from "@/components/Reveal";
import FilterForm from "@/components/FilterForm";
import Card from "./Card";
import { Head, router, usePage } from "@inertiajs/react";
import preferencesImg from "@/assets/images/preferences.svg";
import { useState, useEffect, useRef } from "react";

export default function Index({ pairRequests, filterOptions, pagination }) {
  const { auth } = usePage().props;
  const currentUser = auth.user;
  
  const { tags, userLevels, languages } = filterOptions;
  
  const [allRequests, setAllRequests] = useState(pairRequests);
  const [nextPage, setNextPage] = useState(pagination.next);
  const [isLoading, setIsLoading] = useState(false);
  const loadMoreRef = useRef(null);

  useEffect(() => {
    setAllRequests(pairRequests);
    setNextPage(pagination.next);
  }, [pairRequests]);

  const loadMore = async () => {
    if (!nextPage || isLoading) return;
    
    setIsLoading(true);
    
    const params = new URLSearchParams(window.location.search);
    params.set('page', nextPage);
    
    const response = await fetch(`/pair_requests.json?${params}`);
    const data = await response.json();
    
    setAllRequests([...allRequests, ...data.pairRequests]);
    setNextPage(data.pagination.next);
    setIsLoading(false);
  };

  useEffect(() => {
    const observer = new IntersectionObserver((entries) => {
      if (entries[0].isIntersecting) loadMore();
    });

    if (loadMoreRef.current) observer.observe(loadMoreRef.current);
    
    return () => observer.disconnect();
  }, [nextPage, isLoading, allRequests]);

  return (
    <>
      <div className="flex flex-col items-center w-full">
        <Head title="Pair Programming Requests" />

        <div className="w-full md:w-3/4 xl:w-4/6 2xl:w-1/2">

          <div className="flex w-full items-center mt-12 pb-8 border-b-4 border-black border-dashed text-center">
            <h3 className="text-5xl font-bold">Pair Programming Requests</h3>
          </div>

          <div className="mt-12">
            <Reveal
              button={
                <button className="relative group overflow-hidden items-center w-full flex justify-end mb-2">
                  <span className="absolute block font-bold top-0 -right-[60px] transition ease-in-out duration-500 group-hover:-translate-x-24">
                    Filter
                  </span>
                  <img src={preferencesImg} className="z-10 bg-yellow-50" />
                </button>
              }
            >
              <FilterForm
                tags={tags}
                userLevels={userLevels}
                languages={languages}
                onSubmit={(filters) => {
                  router.get("/pair_requests", { q: filters }, { preserveState: true });
                }}
              />
            </Reveal>
          </div>

          <div className="mt-12">
            {allRequests.map(req => (
              <Card
                key={req.id}
                pairRequest={req}
                currentUserId={currentUser.id}
              />
            ))}
          </div>

          {isLoading && (
            <div className="flex justify-center py-8">
              <div className="text-lg font-bold">Loading more...</div>
            </div>
          )}

          <div ref={loadMoreRef} className="h-10" />

          {!nextPage && allRequests.length > 0 && (
            <div className="flex justify-center py-8 mb-12">
              <div className="text-lg font-bold text-gray-500">No more requests</div>
            </div>
          )}
        </div>
      </div>
    </>
  );
}

Index.layout = page => <AppLayout children={page} />
