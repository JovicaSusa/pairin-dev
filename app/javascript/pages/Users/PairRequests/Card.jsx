import { useForm, Link } from '@inertiajs/react';
import { formatShort } from "@/helpers/date";
import ExpandableText from "@/components/ExpandableText";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarImage, AvatarFallback } from "@/components/ui/avatar";

export default function Card({ request }) {
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
        <Button asChild variant="neutral" className="mt-4 md:mt-0">
          <Link href={`/pair_requests/${request.id}/offers`}>See applications</Link>
        </Button>
      </div>

      <div className="px-4 py-4">
        <ExpandableText>{request.description}</ExpandableText>

        <div className="flex w-full overflow-x-auto justify-start space-x-2 mt-4 pb-2">
          {request.tags?.map((tag) => (
            <Badge
              key={tag.id}
              className="bg-orange shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] 2xl:text-sm"
            >
              {tag.name}
            </Badge>
          ))}
        </div>
      </div>

      {request.accepted_offer && (
        <div className="px-4 pt-4 mt-2">
          <div className="flex flex-col md:flex-row items-center justify-between gap-y-4">
             <div className="flex items-center gap-x-2 w-full md:w-1/2">
                <Avatar className="w-12 h-12 shrink-0">
                  <AvatarImage src={request.accepted_offer.offerer_image} alt={request.accepted_offer.offerer_name} />
                  <AvatarFallback>{request.accepted_offer.offerer_name?.[0]}</AvatarFallback>
                </Avatar>
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

      {request.accepted_offer && (
        <div className="px-4 mt-6">
          <form onSubmit={submitCallLink} className="flex flex-col md:flex-row w-full gap-y-4 md:gap-x-2 items-center md:items-end">
            <div className="flex flex-col w-full">
              <Label className="mb-1">Call link</Label>
              <Input
                type="text"
                value={data.pair_request.sessions_attributes[0]?.call_link}
                onChange={e => {
                  const newAttrs = [...data.pair_request.sessions_attributes];
                  newAttrs[0].call_link = e.target.value;
                  setData('pair_request', { ...data.pair_request, sessions_attributes: newAttrs });
                }}
                placeholder="https://meet.google.com/..."
              />
            </div>
            <Button disabled={processing} className="w-full md:w-1/4">
              {processing ? '...' : 'Add'}
            </Button>
          </form>
        </div>
      )}
    </div>
  );
}
