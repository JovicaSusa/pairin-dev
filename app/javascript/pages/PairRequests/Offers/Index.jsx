import { Head } from "@inertiajs/react";
import { Inbox } from "lucide-react";
import PageHeader from "@/components/PageHeader";
import EmptyState from "@/components/EmptyState";
import Card from './Card';

export default function Index({ offers, pairRequestId }) {
  return (
    <div className="mx-auto w-full max-w-3xl px-4 pb-16 md:px-8">
      <Head title="Applications" />

      <PageHeader eyebrow="Pair Requests" title="Applications" description="Who's applied to pair with you on this request." />

      {offers.length > 0 ? (
        offers.map((offer) => (
          <Card key={offer.id} offer={offer} pairRequestId={pairRequestId} />
        ))
      ) : (
        <EmptyState icon={Inbox} title="No applications yet" description="Share your request in the feed or hang tight — new applicants show up here." />
      )}
    </div>
  );
}
