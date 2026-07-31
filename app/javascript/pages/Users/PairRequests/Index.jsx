import { Head, Link } from '@inertiajs/react';
import { ClipboardList } from "lucide-react";
import PageHeader from "@/components/PageHeader";
import EmptyState from "@/components/EmptyState";
import { Button } from "@/components/ui/button";
import Card from './Card';

export default function Index({ pairRequests }) {
  return (
    <div className="mx-auto w-full max-w-3xl px-4 pb-16 md:px-8">
      <Head title="Your Requests" />

      <PageHeader
        eyebrow="Pair Requests"
        title="Your requests"
        description="Requests you've opened, and who's applied to work with you."
      />

      {pairRequests && pairRequests.length > 0 ? (
        <div id="pair_requests">
          {pairRequests.map((request) => (
            <Card key={request.id} request={request} />
          ))}
        </div>
      ) : (
        <EmptyState icon={ClipboardList} title="You haven't opened any requests yet" description="Post what you're working on and let the community come to you.">
          <Button asChild className="mt-2">
            <Link href="/users/pair_requests/new">Create a request</Link>
          </Button>
        </EmptyState>
      )}
    </div>
  );
}
