import { router } from '@inertiajs/react';
import { formatShort } from "@/helpers/date";
import ExpandableText from "@/components/ExpandableText";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarImage, AvatarFallback } from "@/components/ui/avatar";
import { Card, CardHeader, CardContent, CardFooter } from "@/components/ui/card";

export default function OfferCard({ offer, pairRequestId }) {
  const handleAccept = () => {
    router.post(`/pair_requests/${pairRequestId}/offers/${offer.id}/accept`);
  };

  return (
    <Card className="relative mb-12 bg-white gap-0 py-0 pb-4">
      {offer.should_overlay && (
        <div className="absolute w-full h-full bg-black opacity-20 rounded-base z-10" />
      )}

      <CardHeader className="flex flex-row items-center gap-x-2 px-4 pt-4 pb-0">
        <Avatar className="w-12 h-12 shrink-0">
          <AvatarImage src={offer.offerer.image_url} alt={offer.offerer.name} />
          <AvatarFallback>{offer.offerer.name?.[0]}</AvatarFallback>
        </Avatar>
        <p>{offer.offerer.name}</p>
        {offer.status === "ACCEPTED" && (
          <Badge className="ml-auto bg-green-400 shadow-[2px_2px_0px_0px_rgba(0,0,0,1)]">
            ACCEPTED
          </Badge>
        )}
      </CardHeader>

      <CardContent className="px-2 py-4">
        <ExpandableText className="whitespace-pre-wrap">{offer.message}</ExpandableText>
      </CardContent>

      <CardFooter className="px-4 flex-col md:flex-row items-start md:items-center">
        <div className="md:w-1/2 flex items-center gap-x-2">
          <Badge className="bg-orange">
            {formatShort(offer.start_at)}
          </Badge>
          <span className="block font-bold">:</span>
          <Badge className="bg-orange">
            {formatShort(offer.end_at)}
          </Badge>
        </div>

        <div className="md:w-1/2 md:flex md:justify-end">
          {offer.show_accept_button && (
            <div className="flex justify-center mt-6">
              <Button onClick={handleAccept}>Accept</Button>
            </div>
          )}
        </div>
      </CardFooter>
    </Card>
  );
}
