import { Head, Link } from "@inertiajs/react";
import { Send } from "lucide-react";
import PageHeader from "@/components/PageHeader";
import EmptyState from "@/components/EmptyState";
import { Button } from "@/components/ui/button";
import Card from './Card';

export default function Index({ offers }) {
  return (
    <div className="mx-auto w-full max-w-3xl px-4 pb-16 md:px-8">
      <Head title="Applications" />

      <PageHeader
        eyebrow="Pair Requests"
        title="Applications"
        description="Every offer you've sent, and where it stands."
      />

      {offers.length > 0 ? (
        offers.map((offer) => (
          <Card key={offer.id} offer={offer} />
        ))
      ) : (
        <EmptyState icon={Send} title="You haven't applied to any pair requests yet" description="Browse open requests and find someone to build or learn with.">
          <Button asChild className="mt-2">
            <Link href="/pair_requests">Browse requests</Link>
          </Button>
        </EmptyState>
      )}
    </div>
  );
}
