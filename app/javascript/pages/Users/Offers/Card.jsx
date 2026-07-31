import { formatShort } from "@/helpers/date";
import { ArrowRight } from "lucide-react";
import ExpandableText from "@/components/ExpandableText";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarImage, AvatarFallback } from "@/components/ui/avatar";

const STATUS_STYLES = {
  "ACCEPTED": "bg-green text-black",
  "ACCEPTED OTHER": "bg-black/10 text-black/50",
  "EXPIRED": "bg-red text-white",
  "PENDING": "bg-orange text-white",
};

const StatusBadge = ({ status }) => (
  <Badge className={`rounded-full border-black ${STATUS_STYLES[status] || "bg-black/10 text-black/60"}`}>
    {status}
  </Badge>
);

export default function UserOfferCard({ offer }) {
  return (
    <div className="mb-6 rounded-2xl border-2 border-black bg-white p-5 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] md:p-6">
      <div className="flex flex-col gap-3 md:flex-row md:items-start md:justify-between">
        <h3 className="text-xl">{offer.subject}</h3>
        <div className="flex flex-wrap items-center gap-1.5">
          <Badge variant="neutral" className="rounded-full text-xs">
            {formatShort(offer.start_at)}
          </Badge>
          <ArrowRight className="h-3 w-3 shrink-0 text-black/30" />
          <Badge variant="neutral" className="rounded-full text-xs">
            {formatShort(offer.end_at)}
          </Badge>
        </div>
      </div>

      <div className="mt-4 flex items-center gap-3">
        <Avatar className="h-11 w-11 shrink-0 border-2 border-black">
          <AvatarImage src={offer.owner.image_url} alt={offer.owner.name} />
          <AvatarFallback className="bg-orange text-white font-bold">{offer.owner.name?.[0]}</AvatarFallback>
        </Avatar>
        <div>
          <p className="font-bold text-sm">{offer.owner.name}</p>
          <span className="text-xs text-black/50">
            {offer.owner.profession}
            {offer.owner.profession && offer.owner.level && " · "}
            {offer.owner.level}
          </span>
        </div>
      </div>

      <ExpandableText className="mt-4 whitespace-pre-wrap leading-relaxed text-black/60">{offer.message}</ExpandableText>

      <div className="mt-4 flex justify-end">
        <StatusBadge status={offer.status} />
      </div>
    </div>
  );
}
