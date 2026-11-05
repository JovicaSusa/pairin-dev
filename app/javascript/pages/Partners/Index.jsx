import { Head, Link } from "@inertiajs/react";
import { Users } from "lucide-react";
import EmptyState from "@/components/EmptyState";
import PageHeader from "@/components/PageHeader";
import { Face } from "@/components/ConversationParts";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";

export default function Index({ partnerships }) {
  return (
    <div className="mx-auto w-full max-w-3xl px-4 pb-16 md:px-8">
      <Head title="Partners" />

      <PageHeader eyebrow="Partners" title="Your partners" description="The people you've committed to learning with." />

      {partnerships.length > 0 ? (
        <ul className="flex flex-col gap-4">
          {partnerships.map((p) => (
            <li key={p.id}>
              <Link
                href={`/partners/${p.id}`}
                className="flex items-center gap-3 rounded-2xl border-2 border-black bg-white p-4 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] hover:bg-yellow-50"
              >
                <Face person={p.partner} />
                <div className="min-w-0 flex-1">
                  <p className="font-bold">{p.partner.name}</p>
                  <p className="truncate text-sm text-black/65">{p.goal ?? p.subject}</p>
                </div>
                {p.ended && <Badge className="rounded-full border-black bg-black/10 text-xs text-black/65">Ended</Badge>}
              </Link>
            </li>
          ))}
        </ul>
      ) : (
        <EmptyState icon={Users} title="No partners yet" description="When you and someone you've been talking to both say yes, your Workspace opens here.">
          <Button asChild className="mt-2">
            <Link href="/conversations">Go to your conversations</Link>
          </Button>
        </EmptyState>
      )}
    </div>
  );
}
