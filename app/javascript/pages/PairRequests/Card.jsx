import { Link } from "@inertiajs/react";
import { ArrowRight } from "lucide-react";
import { formatShort } from "@/helpers/date";
import ExpandableText from "@/components/ExpandableText";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarImage, AvatarFallback } from "@/components/ui/avatar";

const TAG_COLORS = ["bg-purple text-white", "bg-orange text-white", "bg-green text-black"];

export default function PairRequestCard({ pairRequest, currentUserId, live = false }) {
  const alreadyOffered = pairRequest.offers
    ?.map(o => o.offerer_id)
    .includes(currentUserId);

  return (
    <div className="mb-6 rounded-2xl border-2 border-black bg-white p-5 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] transition-all hover:-translate-y-0.5 hover:shadow-[6px_6px_0px_0px_rgba(0,0,0,1)] md:p-6">
      <div className="flex flex-col gap-3 md:flex-row md:items-start md:justify-between">
        <h3 className="text-xl">{pairRequest.subject}</h3>

        {live ? (
          <Badge className="rounded-full border-black bg-green text-black text-xs">Live now</Badge>
        ) : (
          <div className="flex flex-wrap gap-2 md:flex-col md:items-end">
            {pairRequest.periods.map((period) => (
              <div key={period.id} className="flex items-center gap-1.5">
                <Badge variant="neutral" className="rounded-full text-xs">
                  {formatShort(period.start_at)}
                </Badge>
                <ArrowRight className="h-3 w-3 shrink-0 text-black/30" />
                <Badge variant="neutral" className="rounded-full text-xs">
                  {formatShort(period.end_at)}
                </Badge>
              </div>
            ))}
          </div>
        )}
      </div>

      <ExpandableText className="mt-3 leading-relaxed text-black/60">{pairRequest.description}</ExpandableText>

      {live && pairRequest.goal && (
        <p className="mt-3 text-sm text-black/60"><span className="font-bold text-black">Goal:</span> {pairRequest.goal}</p>
      )}

      {live && pairRequest.platform && (
        <p className="mt-1 text-sm text-black/60"><span className="font-bold text-black">Platform:</span> {pairRequest.platform}</p>
      )}

      <div className="mt-4 flex flex-wrap gap-2">
        {pairRequest.tags.map((tag, i) => (
          <Badge key={tag.id} className={`rounded-full border-black ${TAG_COLORS[i % TAG_COLORS.length]}`}>
            {tag.name}
          </Badge>
        ))}
      </div>

      <div className="mt-5 flex flex-col gap-4 border-t-2 border-black/10 pt-4 md:flex-row md:items-center md:justify-between">
        <div className="flex items-center gap-3">
          <Avatar className="h-11 w-11 border-2 border-black">
            <AvatarImage src={pairRequest.user.image_url} alt={pairRequest.user.name} />
            <AvatarFallback className="bg-orange text-white font-bold">{pairRequest.user.name?.[0]}</AvatarFallback>
          </Avatar>
          <div>
            <p className="font-bold text-sm">{pairRequest.user.name}</p>
            <span className="text-xs text-black/50">
              {pairRequest.user.profession}
              {pairRequest.user.profession && pairRequest.user.level_titleized && " · "}
              {pairRequest.user.level_titleized}
            </span>
          </div>
        </div>

        {!live && (
          alreadyOffered ? (
            <span className="text-sm font-bold italic text-black/40">You have already sent an offer</span>
          ) : (
            <Button asChild>
              <Link href={`/pair_requests/${pairRequest.id}/offers/new`}>Apply</Link>
            </Button>
          )
        )}
      </div>
    </div>
  );
}
