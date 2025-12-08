import { useState, useEffect, useRef } from "react";
import { Link } from "@inertiajs/react";
import { formatShort } from "@/helpers/date";
import logoImg from "@/assets/images/logo.svg"

export default function Card({ pairRequest, currentUserId }) {
  const [expanded, setExpanded] = useState(false);
  const [showButton, setShowButton] = useState(false);
  const contentRef = useRef(null);

  
  useEffect(() => {
    const el = contentRef.current;
    if (!el) return;

    const isOverflowing = el.scrollHeight > el.clientHeight;
    setShowButton(isOverflowing);
  }, []);

  const alreadyOffered = pairRequest.offers
    ?.map(o => o.offerer_id)
    .includes(currentUserId);

  return (
    <div className="mb-12 border-2 pb-4 border-black rounded-t-md bg-white shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]">
      <div className="border-b-2 border-black py-4 px-2 rounded-t-md bg-green">
        <h3 className="font-bold text-xl">{pairRequest.subject}</h3>
      </div>

      <div className="md:flex max-h-fit px-2 py-4">
        <div className="w-full md:w-7/12">
          <p ref={contentRef} className={`${expanded ? "line-clamp-none" : "line-clamp-3"}`}>
              {pairRequest.description}
          </p>
          {showButton && (
            <button className="underline" onClick={() => setExpanded((prev) => !prev)}>
              {expanded ? "Read less" : "Read more"}
            </button>
          )}
        </div>

        <div className="w-full mt-4 md:mt-0 md:w-5/12">
          {pairRequest.periods.map((period) => (
            <div
              key={period.id}
              className="w-full flex md:items-center md:justify-end gap-x-1 mt-1"
            >
              <div className="rounded-xl text-sm border-2 border-black px-2 font-semibold">
                {formatShort(period.start_at)}
              </div>

              <span className="block font-bold">:</span>

              <div className="rounded-xl text-sm border-2 border-black px-2 font-semibold">
                {formatShort(period.end_at)}
              </div>
            </div>
          ))}
        </div>
      </div>

      <div className="flex w-full overflow-x-scroll justify-start space-x-2 py-2 px-2 mb-6">
        {pairRequest.tags.map((tag) => (
          <div
            key={tag.id}
            className="max-w-max whitespace-nowrap rounded-full border-2 border-black bg-orange px-2 py-1 text-xs 2xl:text-sm font-bold shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] transition-all hover:translate-x-[3px] hover:translate-y-[3px] hover:shadow-none"
          >
            {tag.name}
          </div>
        ))}
      </div>

      <div className="px-4 md:flex md:items-center">
        <div className="md:w-1/2 flex items-center gap-x-2">
          <figure className="border-2 border-black w-12 h-12 overflow-hidden rounded-md">
            <img src={pairRequest.user.image_url || logoImg} />
          </figure>

          <div>
            <p>{pairRequest.user.name}</p>
            <span className="text-sm">
              {pairRequest.user.profession}
              <span className="text-xl font-bold">.</span>
              {pairRequest.user.level_titleized}
            </span>
          </div>
        </div>

        <div className="md:w-1/2 mt-4 md:mt-0 md:flex md:justify-end">
          {alreadyOffered ? (
            <p>You have already sent an offer</p>
          ) : (
            <Link
              href={`/pair_requests/${pairRequest.id}/offers/new`}
              className="flex md:w-1/2 cursor-pointer items-center justify-center rounded-md border-2 border-black bg-purple px-10 py-3 font-bold shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] transition-all hover:translate-x-[3px] hover:translate-y-[3px] hover:shadow-none"
            >
              Apply
            </Link>
          )}
        </div>
      </div>
    </div>
  );
}
