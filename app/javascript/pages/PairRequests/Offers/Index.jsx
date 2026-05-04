import { Head } from "@inertiajs/react";
import Card from './Card';

export default function Index({ offers, pair_request_id }) {
  return (
    <div className="flex flex-col items-center">
      <Head title="Applications" />

      <div className="w-full md:w-3/4 xl:w-4/6 2xl:w-1/2">
        <div className="flex w-full items-center mt-12 pb-8 border-b-4 border-black border-dashed">
          <h3 className="text-5xl font-bold">Applications</h3>
        </div>

        <div className="mt-12">
          {offers.length > 0 ? (
            offers.map((offer) => (
              <Card key={offer.id} offer={offer} pairRequestId={pair_request_id} />
            ))
          ) : (
            <div className="border-4 border-dashed border-black rounded-md p-12 text-center bg-white shadow-[8px_8px_0px_0px_rgba(0,0,0,1)]">
              <p className="text-2xl font-bold italic text-gray-400">
                No applications yet.
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

