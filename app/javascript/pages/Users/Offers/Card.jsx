import { formatShort } from "@/helpers/date";
import ExpandableText from "@/components/ExpandableText";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarImage, AvatarFallback } from "@/components/ui/avatar";
import { Card, CardHeader, CardTitle, CardContent, CardFooter } from "@/components/ui/card";

const StatusBadge = ({ status }) => {
  const styles = {
    "ACCEPTED": "bg-green",
    "ACCEPTED OTHER": "bg-gray-200 text-gray-500",
    "EXPIRED": "bg-red text-white",
    "PENDING": "bg-orange"
  };

  return (
    <Badge className={styles[status] || 'bg-white'}>
      {status}
    </Badge>
  );
};

export default function UserOfferCard({ offer }) {
  return (
    <Card className="mb-12 bg-white gap-0 py-0 pb-4">
      <CardHeader className="flex flex-col md:flex-row justify-between items-start md:items-center border-b-2 border-border bg-green px-2 py-3 rounded-t-base gap-y-2">
        <CardTitle>{offer.subject}</CardTitle>
        <div className="flex items-center gap-x-2">
          <Badge className="bg-orange">
            {formatShort(offer.start_at)}
          </Badge>
          <span className="block font-bold">:</span>
          <Badge className="bg-orange">
            {formatShort(offer.end_at)}
          </Badge>
        </div>
      </CardHeader>

      <div className="px-2 mt-4 flex items-center gap-x-2">
        <Avatar className="w-12 h-12 shrink-0">
          <AvatarImage src={offer.owner.image_url} alt={offer.owner.name} />
          <AvatarFallback>{offer.owner.name?.[0]}</AvatarFallback>
        </Avatar>
        <div>
          <p>{offer.owner.name}</p>
          <span className="text-sm">
            {offer.owner.profession}
            <span className="text-xl font-bold">.</span>
            {offer.owner.level}
          </span>
        </div>
      </div>

      <CardContent className="px-2 py-4">
        <ExpandableText className="whitespace-pre-wrap">{offer.message}</ExpandableText>
      </CardContent>

      <CardFooter className="flex justify-end px-2">
        <StatusBadge status={offer.status} />
      </CardFooter>
    </Card>
  );
}
