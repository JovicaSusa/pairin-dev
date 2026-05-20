import { Link } from "@inertiajs/react";
import { formatShort } from "@/helpers/date";
import ExpandableText from "@/components/ExpandableText";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarImage, AvatarFallback } from "@/components/ui/avatar";
import { Card, CardHeader, CardTitle, CardContent, CardFooter } from "@/components/ui/card";

export default function PairRequestCard({ pairRequest, currentUserId }) {
  const alreadyOffered = pairRequest.offers
    ?.map(o => o.offerer_id)
    .includes(currentUserId);

  return (
    <Card className="mb-12 bg-white gap-0 py-0 pb-4">
      <CardHeader className="border-b-2 border-border bg-green py-4 px-2 rounded-t-base">
        <CardTitle className="text-xl">{pairRequest.subject}</CardTitle>
      </CardHeader>

      <CardContent className="md:flex max-h-fit px-2 py-4">
        <div className="w-full md:w-7/12">
          <ExpandableText>{pairRequest.description}</ExpandableText>
        </div>

        <div className="w-full mt-4 md:mt-0 md:w-5/12">
          {pairRequest.periods.map((period) => (
            <div
              key={period.id}
              className="w-full flex md:items-center md:justify-end gap-x-1 mt-1"
            >
              <Badge variant="neutral" className="text-sm">
                {formatShort(period.start_at)}
              </Badge>
              <span className="block font-bold">:</span>
              <Badge variant="neutral" className="text-sm">
                {formatShort(period.end_at)}
              </Badge>
            </div>
          ))}
        </div>
      </CardContent>

      <div className="flex w-full overflow-x-scroll justify-start space-x-2 py-2 px-2 mb-6">
        {pairRequest.tags.map((tag) => (
          <Badge
            key={tag.id}
            className="bg-orange shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] transition-all hover:translate-x-[3px] hover:translate-y-[3px] hover:shadow-none 2xl:text-sm"
          >
            {tag.name}
          </Badge>
        ))}
      </div>

      <CardFooter className="px-4 flex-col md:flex-row items-start md:items-center">
        <div className="md:w-1/2 flex items-center gap-x-2">
          <Avatar className="w-12 h-12">
            <AvatarImage src={pairRequest.user.image_url} alt={pairRequest.user.name} />
            <AvatarFallback>{pairRequest.user.name?.[0]}</AvatarFallback>
          </Avatar>

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
            <Button asChild className="md:w-1/2">
              <Link href={`/pair_requests/${pairRequest.id}/offers/new`}>Apply</Link>
            </Button>
          )}
        </div>
      </CardFooter>
    </Card>
  );
}
