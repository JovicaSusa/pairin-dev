import { useForm, Link } from '@inertiajs/react';
import { Inbox, CheckCircle2 } from "lucide-react";
import { formatShort } from "@/helpers/date";
import ExpandableText from "@/components/ExpandableText";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarImage, AvatarFallback } from "@/components/ui/avatar";

const TAG_COLORS = ["bg-purple text-white", "bg-orange text-white", "bg-green text-black"];

export default function UserPairRequestCard({ request }) {
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
    <div className="mb-6 rounded-2xl border-2 border-black bg-white p-5 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] md:p-6">
      <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <h3 className="text-xl">{request.subject}</h3>
        <Button asChild variant="neutral" size="sm">
          <Link href={`/pair_requests/${request.id}/offers`}>
            <Inbox className="h-4 w-4" />
            See applications
          </Link>
        </Button>
      </div>

      <ExpandableText className="mt-3 leading-relaxed text-black/60">{request.description}</ExpandableText>

      <div className="mt-4 flex flex-wrap gap-2">
        {request.tags?.map((tag, i) => (
          <Badge key={tag.id} className={`rounded-full border-black ${TAG_COLORS[i % TAG_COLORS.length]}`}>
            {tag.name}
          </Badge>
        ))}
      </div>

      {request.accepted_offer && (
        <div className="mt-5 rounded-xl border-2 border-black bg-green/10 p-4">
          <Badge className="mb-3 rounded-full border-black bg-green text-black uppercase tracking-widest">
            <CheckCircle2 className="h-3.5 w-3.5" />
            Matched
          </Badge>

          <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
            <div className="flex items-center gap-3">
              <Avatar className="h-11 w-11 shrink-0 border-2 border-black">
                <AvatarImage src={request.accepted_offer.offerer_image} alt={request.accepted_offer.offerer_name} />
                <AvatarFallback className="bg-orange text-white font-bold">{request.accepted_offer.offerer_name?.[0]}</AvatarFallback>
              </Avatar>
              <div>
                <p className="font-bold text-sm">{request.accepted_offer.offerer_name}</p>
                <span className="text-xs text-black/50">
                  {request.accepted_offer.offerer_profession}
                  {request.accepted_offer.offerer_profession && " · "}
                  {request.accepted_offer.offerer_level}
                </span>
              </div>
            </div>

            <div className="flex flex-col gap-1 md:items-end">
              {request.sessions.map(s => (
                <div key={s.id} className="flex items-center gap-1.5">
                  <Badge variant="neutral" className="rounded-full text-xs">
                    {formatShort(s.start_at)}
                  </Badge>
                  <span className="text-black/30">→</span>
                  <Badge variant="neutral" className="rounded-full text-xs">
                    {formatShort(s.end_at)}
                  </Badge>
                </div>
              ))}
            </div>
          </div>

          <form onSubmit={submitCallLink} className="mt-4 flex flex-col items-stretch gap-2 md:flex-row md:items-end">
            <div className="flex flex-1 flex-col">
              <Label htmlFor="pair_request_sessions_attributes_0_call_link" className="mb-1">Call link</Label>
              <Input
                id="pair_request_sessions_attributes_0_call_link"
                type="text"
                value={data.pair_request.sessions_attributes[0]?.call_link}
                onChange={e => {
                  const newAttrs = [...data.pair_request.sessions_attributes];
                  newAttrs[0].call_link = e.target.value;
                  setData('pair_request', { ...data.pair_request, sessions_attributes: newAttrs });
                }}
                placeholder="https://meet.google.com/..."
                className="bg-white"
              />
            </div>
            <Button disabled={processing} className="md:w-32">
              {processing ? '...' : 'Add'}
            </Button>
          </form>
        </div>
      )}
    </div>
  );
}
