import { router, useForm } from "@inertiajs/react";
import { Link2, Trash2 } from "lucide-react";
import { TAP_AREA } from "@/components/ConversationParts";
import WorkspaceFrame from "@/components/WorkspaceFrame";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

const PANEL = "rounded-2xl border-2 border-black bg-white shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]";

function AddLinkForm({ partnership }) {
  const { data, setData, post, processing, errors, reset } = useForm({ url: "", note: "" });

  const submit = (e) => {
    e.preventDefault();
    post(`/partners/${partnership.id}/resources`, { preserveScroll: true, onSuccess: () => reset() });
  };

  return (
    <form onSubmit={submit} className={`flex flex-col gap-3 p-4 md:p-5 ${PANEL}`}>
      <p className="font-bold">Add a link</p>
      <div>
        <Label htmlFor="resource_url" className="mb-1 block text-sm">Link</Label>
        <Input id="resource_url" type="url" required placeholder="https://…" value={data.url} onChange={(e) => setData("url", e.target.value)} />
        {errors.url && <p className="mt-1 text-sm font-bold text-red">{errors.url}</p>}
      </div>
      <div>
        <Label htmlFor="resource_note" className="mb-1 block text-sm">Note (optional)</Label>
        <Input id="resource_note" placeholder="What it's for" value={data.note} onChange={(e) => setData("note", e.target.value)} />
        {errors.note && <p className="mt-1 text-sm font-bold text-red">{errors.note}</p>}
      </div>
      <div>
        <Button type="submit" size="sm" disabled={processing}>Add link</Button>
      </div>
    </form>
  );
}

function ResourceCard({ resource, partnership }) {
  const name = partnership.conversation.other.name;
  const remove = () => router.delete(`/partners/${partnership.id}/resources/${resource.id}`, { preserveScroll: true });

  return (
    <li className={`flex min-w-0 items-start gap-2 p-4 ${PANEL}`}>
      <Link2 className="mt-1 h-4 w-4 shrink-0" aria-hidden="true" />
      <div className="min-w-0 flex-1">
        <a href={resource.url} target="_blank" rel="noopener noreferrer nofollow" className="block truncate font-bold underline" title={resource.url}>
          {resource.host}
        </a>
        <p className="truncate text-xs text-black/65">{resource.url.replace(/^https?:\/\/(www\.)?/, "")}</p>
        {resource.note && <p className="mt-0.5 break-words text-sm">{resource.note}</p>}
        <p className="mt-1 text-xs text-black/65">Added by {resource.mine ? "you" : name}</p>
      </div>
      {!partnership.ended && (
        <button type="button" aria-label={`Remove ${resource.host}`} onClick={remove} className={`shrink-0 text-black/65 hover:text-black ${TAP_AREA}`}>
          <Trash2 className="h-4 w-4" />
        </button>
      )}
    </li>
  );
}

// The Workspace's Resources page: links either partner wants to keep (#186).
export default function Resources({ partnership }) {
  const { resources } = partnership;

  return (
    <WorkspaceFrame partnership={partnership} title="Resources" back={{ href: `/partners/${partnership.id}`, label: "Overview" }}>
      <div className="grid grid-cols-1 items-start gap-4 md:gap-6 lg:grid-cols-[340px_minmax(0,1fr)]">
        {!partnership.ended && <AddLinkForm partnership={partnership} />}
        <div className={partnership.ended ? "lg:col-span-2" : ""}>
          {resources.length === 0 ? (
            <p className="text-black/65">Nothing shared yet. Docs, repos and exercises you both want to keep go here.</p>
          ) : (
            <ul className="grid grid-cols-1 gap-3 sm:grid-cols-2">
              {resources.map((resource) => <ResourceCard key={resource.id} resource={resource} partnership={partnership} />)}
            </ul>
          )}
        </div>
      </div>
    </WorkspaceFrame>
  );
}
