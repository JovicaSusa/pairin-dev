import Reveal from "@/components/Reveal";
import FilterForm from "@/components/FilterForm";
import Card from "./Card";
import { Head, router } from "@inertiajs/react";
import preferencesImg from "@/assets/images/preferences.svg";

export default function Index({ pairRequests, currentUser, filterOptions }) {
  const { tags, userLevels, languages } = filterOptions;

  return (
    <div className="flex flex-col items-center">
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
          {pairRequests.map(req => (
            <Card
              key={req.id}
              pairRequest={req}
              currentUserId={currentUser.id}
            />
          ))}
        </div>
      </div>
    </div>
  );
}
