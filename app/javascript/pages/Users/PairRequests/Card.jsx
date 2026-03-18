import { useForm, Link } from '@inertiajs/react';
import { useState, useEffect, useRef } from 'react';
import { formatShort } from "@/helpers/date";

export default function RequestCard({ request }) {
  const [expanded, setExpanded] = useState(false);
  const [showButton, setShowButton] = useState(false);
  const contentRef = useRef(null);

  useEffect(() => {
    const el = contentRef.current;
    if (!el) return;

    const isOverflowing = el.scrollHeight > el.clientHeight;
    setShowButton(isOverflowing);
  }, [request.description]);
  
  const { data, setData, patch, processing } = useForm({
    pair_request: {
      sessions_attributes: request.sessions.map(s => ({ 
        id: s.id, 
        call_link: s.call_link || ''
      }))
    }
  });

  const submitCallLink = (e) => {
    e.preventDefault();
    patch(`/users/pair_requests/${request.id}/add_call_link`);
  };

  return (
    <div className="mb-12 border-2 pb-4 border-black rounded-t-md bg-white shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]">
      <div className="w-full border-b-2 flex flex-col md:flex-row justify-between items-center border-black py-4 px-4 rounded-t-md bg-green">
        <h3 className="font-bold text-xl">{request.subject}</h3>
        <Link 
          href={`/pair_requests/${request.id}/offers`} 
          className="rounded-md border-2 border-black bg-white px-6 py-2 font-bold shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] hover:translate-x-[2px] hover:translate-y-[2px] hover:shadow-none transition-all mt-4 md:mt-0"
        >
          See applications
        </Link>
      </div>

      <div className="px-4 py-4">
        <p ref={contentRef} className={`${expanded ? "line-clamp-none" : "line-clamp-3"}`}>
            {request.description}
        </p>
        {showButton && (
          <button className="underline" onClick={() => setExpanded((prev) => !prev)}>
            {expanded ? "Read less" : "Read more"}
          </button>
        )}

        <div className="flex w-full overflow-x-auto justify-start space-x-2 mt-4 pb-2">
          {request.tags?.map((tag) => (
            <div
              key={tag.id}
              className="max-w-max whitespace-nowrap rounded-full border-2 border-black bg-orange px-2 py-1 text-xs 2xl:text-sm font-bold shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] transition-all"
            >
              {tag.name}
            </div>
          ))}
        </div>
      </div>

      {request.accepted_offer && (
        <div className="px-4 pt-4 mt-2">
          <div className="flex flex-col md:flex-row items-center justify-between gap-y-4">
             <div className="flex items-center gap-x-2 w-full md:w-1/2">
                <figure className="border-2 border-black w-12 h-12 overflow-hidden rounded-md shrink-0">
                  <img src={request.accepted_offer.offerer_image} className="w-full h-full object-contain" />
                </figure>
                <div>
                  <p className="font-bold">{request.accepted_offer.offerer_name}</p>
                  <span className="text-sm">
                    {request.accepted_offer.offerer_profession}
                    <span className="text-gray-400 font-black"> &bull; </span>
                    {request.accepted_offer.offerer_level}
                  </span>
                </div>
             </div>

             <div className="flex flex-col gap-y-1 w-full md:w-1/2 md:items-end">
               {request.sessions.map(s => (
                 <div key={s.id} className="flex items-center gap-x-1">
                    <div className="rounded-xl text-sm border-2 border-black px-3 py-0.5 font-bold bg-white">
                      {formatShort(s.start_at)}
                    </div>
                    <span className="font-bold">:</span>
                    <div className="rounded-xl text-sm border-2 border-black px-3 py-0.5 font-bold bg-white">
                      {formatShort(s.end_at)}
                    </div>
                 </div>
               ))}
             </div>
          </div>
        </div>
      )}

      {request.has_accepted_offer && (
        <div className="px-4 mt-6">
          <form onSubmit={submitCallLink} className="flex flex-col md:flex-row w-full gap-y-4 md:gap-x-2 items-center md:items-end">
            <div className="flex flex-col w-full">
              <label className="font-bold text-sm mb-1 ml-1">Call link</label>
              <input 
                type="text"
                value={data.pair_request.sessions_attributes[0]?.call_link}
                onChange={e => {
                  const newAttrs = [...data.pair_request.sessions_attributes];
                  newAttrs[0].call_link = e.target.value;
                  setData('pair_request', { ...data.pair_request, sessions_attributes: newAttrs });
                }}
                placeholder="https://meet.google.com/..."
                className="w-full rounded-md border-2 border-black p-2 font-bold shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] outline-none transition-all focus:translate-x-[2px] focus:translate-y-[2px] focus:shadow-none"
              />
            </div>
            <button 
              disabled={processing}
              className="w-full md:w-1/4 bg-purple border-2 border-black px-10 py-3 rounded-md font-bold shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] transition-all hover:translate-x-[3px] hover:translate-y-[3px] hover:shadow-none"
            >
              {processing ? '...' : 'Add'}
            </button>
          </form>
        </div>
      )}
    </div>
  );
}
