import { router } from '@inertiajs/react';
import { formatShort } from "@/helpers/date";
import ExpandableText from "@/components/ExpandableText";

export default function Card({ offer, pairRequestId }) {
  const handleAccept = () => {
    router.post(`/pair_requests/${pairRequestId}/offers/${offer.id}/accept`);
  };

  return (
    <div className="relative mb-12 border-2 pb-4 border-black rounded-t-md bg-white shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]">
      {offer.should_overlay && (
        <div className="absolute w-full h-full bg-black opacity-20 rounded-t-md z-10" />
      )}

      <div className="flex items-center gap-x-2 px-4 pt-4">
        <figure className="border-2 border-black w-12 h-12 overflow-hidden rounded-md shrink-0">
          <img src={offer.offerer.image_url} alt={offer.offerer.name} className="w-full h-full object-cover" />
        </figure>
        <p>{offer.offerer.name}</p>
        {offer.status === "ACCEPTED" && (
          <span className="ml-auto bg-green-400 border-2 border-black px-2 py-1 rounded-md text-xs font-bold shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]">
            ACCEPTED
          </span>
        )}
      </div>

      <div className="px-2 py-4">
        <ExpandableText className="whitespace-pre-wrap">{offer.message}</ExpandableText>
      </div>

      <div className="px-4 md:flex md:items-center">
        <div className="md:w-1/2 flex items-center gap-x-2">
          <div className="rounded-xl border-2 border-black bg-orange px-2 font-semibold">
            {formatShort(offer.start_at)}
          </div>
          <span className="block font-bold">:</span>
          <div className="rounded-xl border-2 border-black bg-orange px-2 font-semibold">
            {formatShort(offer.end_at)}
          </div>
        </div>

        <div className="md:w-1/2 md:flex md:justify-end">
          {offer.show_accept_button && (
            <div className="flex justify-center mt-6">
              <button
                onClick={handleAccept}
                className="flex cursor-pointer items-center rounded-md border-2 border-black bg-purple px-5 py-3 font-bold shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] transition-all hover:translate-x-[3px] hover:translate-y-[3px] hover:shadow-none"
              >
                Accept
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
