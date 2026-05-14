import { formatShort } from "@/helpers/date";
import ExpandableText from "@/components/ExpandableText";

const StatusBadge = ({ status }) => {
  const styles = {
    "ACCEPTED": "bg-green",
    "ACCEPTED OTHER": "bg-gray-200 text-gray-500",
    "EXPIRED": "bg-red text-white",
    "PENDING": "bg-orange"
  };

  return (
    <div className={`border-2 border-black rounded-xl px-2 font-bold text-xs ${styles[status] || 'bg-white'}`}>
      {status}
    </div>
  );
};

export default function Card({ offer }) {
  return (
    <div className="mb-12 border-2 pb-4 border-black rounded-t-md bg-white shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]">
      <div className="border-b-2 border-black px-2 py-3 rounded-t-md bg-green flex flex-col md:flex-row justify-between items-start md:items-center gap-y-2">
        <p className="font-bold">{offer.subject}</p>

        <div className="flex items-center gap-x-2">
          <div className="rounded-xl text-sm border-2 border-black bg-orange px-2 font-semibold">
            {formatShort(offer.start_at)}
          </div>
          <span className="block font-bold">:</span>
          <div className="rounded-xl text-sm border-2 border-black bg-orange px-2 font-semibold">
            {formatShort(offer.end_at)}
          </div>
        </div>
      </div>

      <div className="px-2 mt-4 flex items-center gap-x-2">
        <figure className="border-2 border-black w-12 h-12 overflow-hidden rounded-md shrink-0">
          <img src={offer.owner.image_url} alt={offer.owner.name} className="w-full h-full object-cover" />
        </figure>
        <div>
          <p>{offer.owner.name}</p>
          <span className="text-sm">
            {offer.owner.profession}
            <span className="text-xl font-bold">.</span>
            {offer.owner.level}
          </span>
        </div>
      </div>

      <div className="px-2 py-4">
        <ExpandableText className="whitespace-pre-wrap">{offer.message}</ExpandableText>
      </div>

      <div className="flex justify-end px-2">
        <StatusBadge status={offer.status} />
      </div>
    </div>
  );
}
