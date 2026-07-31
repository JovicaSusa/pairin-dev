import { router } from '@inertiajs/react';
import { ArrowRight, CheckCircle2 } from "lucide-react";
import { formatShort } from "@/helpers/date";
import ExpandableText from "@/components/ExpandableText";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarImage, AvatarFallback } from "@/components/ui/avatar";

export default function OfferCard({ offer, pairRequestId }) {
  const handleAccept = () => {
    router.post(`/pair_requests/${pairRequestId}/offers/${offer.id}/accept`);
  };

  return (
    <div
      className={`relative mb-6 rounded-2xl border-2 border-black bg-white p-5 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] md:p-6 ${
        offer.should_overlay ? "opacity-50" : ""
      }`}
    >
      <div className="flex flex-wrap items-center gap-3">
        <Avatar className="h-11 w-11 shrink-0 border-2 border-black">
          <AvatarImage src={offer.offerer.image_url} alt={offer.offerer.name} />
          <AvatarFallback className="bg-orange text-white font-bold">{offer.offerer.name?.[0]}</AvatarFallback>
        </Avatar>
        <p className="font-bold">{offer.offerer.name}</p>
        {offer.status === "ACCEPTED" && (
          <Badge className="ml-auto rounded-full border-black bg-green text-black">
            <CheckCircle2 className="h-3.5 w-3.5" />
            Accepted
          </Badge>
        )}
      </div>

      <ExpandableText className="mt-4 whitespace-pre-wrap leading-relaxed text-black/60">{offer.message}</ExpandableText>

      <div className="mt-4 flex flex-col gap-4 border-t-2 border-black/10 pt-4 md:flex-row md:items-center md:justify-between">
        <div className="flex items-center gap-1.5">
          <Badge variant="neutral" className="rounded-full text-xs">
            {formatShort(offer.start_at)}
          </Badge>
          <ArrowRight className="h-3 w-3 shrink-0 text-black/30" />
          <Badge variant="neutral" className="rounded-full text-xs">
            {formatShort(offer.end_at)}
          </Badge>
        </div>

        {offer.show_accept_button && (
          <Button onClick={handleAccept}>Accept</Button>
        )}
      </div>
    </div>
  );
}
