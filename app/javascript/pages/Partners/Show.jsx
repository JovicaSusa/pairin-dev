import { Link, useForm } from "@inertiajs/react";
import { useState } from "react";
import { Check, Link2, Lock, MessageSquare } from "lucide-react";
import { TAP_AREA } from "@/components/ConversationParts";
import WorkspaceFrame, { Goal } from "@/components/WorkspaceFrame";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";

const PANEL = "rounded-2xl border-2 border-black shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]";
const TILE_LABEL = "text-xs font-bold uppercase tracking-widest";

function EndPartnership({ partnership }) {
  const [open, setOpen] = useState(false);
  const { data, setData, post, processing } = useForm({ reason: "" });
  const name = partnership.conversation.other.name;

  if (!open) {
    return (
      <button type="button" onClick={() => setOpen(true)} className={`text-left text-xs font-bold text-black/65 underline hover:text-black ${TAP_AREA}`}>
        End partnership
      </button>
    );
  }

  return (
    <form
      className="rounded-2xl border-2 border-black bg-yellow-50 p-4"
      onSubmit={(e) => {
        e.preventDefault();
        post(`/partners/${partnership.id}/end_partnership`, { preserveScroll: true });
      }}
    >
      <p className="text-sm font-bold">End this partnership?</p>
      <p className="mb-2 text-xs text-black/65">We'll tell {name} kindly. The Workspace stays readable, but neither of you can write here afterwards.</p>
      <Label htmlFor="end_reason" className="mb-1 block text-xs">Why? (optional, only we see this)</Label>
      <Textarea id="end_reason" rows={2} value={data.reason} onChange={(e) => setData("reason", e.target.value)} />
      <div className="mt-2 flex gap-2">
        <Button type="submit" size="sm" disabled={processing}>End partnership</Button>
        <Button type="button" size="sm" variant="neutral" onClick={() => setOpen(false)}>Keep going</Button>
      </div>
    </form>
  );
}

function ChatTile({ partnership }) {
  const { unread, last_message: last } = partnership;
  const name = partnership.conversation.other.name;
  const fresh = unread > 0;

  return (
    <Link
      href={`/partners/${partnership.id}/chat`}
      className={`flex flex-col items-start gap-2 p-4 transition-transform hover:-translate-y-0.5 md:p-5 ${PANEL} ${fresh ? "bg-purple text-white" : "bg-white"}`}
    >
      <span className={`flex items-center gap-1.5 ${TILE_LABEL}`}>
        <MessageSquare className="h-4 w-4" />
        Chat
      </span>
      {fresh ? (
        <span className="flex items-baseline gap-1.5">
          <span className="text-4xl font-bold leading-none md:text-5xl">{unread}</span>
          <span className="text-sm font-bold">new {unread === 1 ? "message" : "messages"}</span>
        </span>
      ) : (
        <span className="text-lg font-bold">You're all caught up</span>
      )}
      {last && (
        <span className={`line-clamp-2 break-words text-sm ${fresh ? "text-white" : "text-black/65"}`}>
          {last.mine ? "You" : name}: {last.body}
        </span>
      )}
      <span className="mt-auto text-sm font-bold underline">Open chat</span>
    </Link>
  );
}

function WeeksTile({ partnership }) {
  const { weeks } = partnership;
  const yes = weeks.filter((w) => w.worked_together).length;
  const nextCheckIn = new Intl.DateTimeFormat(undefined, { weekday: "long", day: "numeric", month: "long" }).format(new Date(partnership.next_check_in_at));

  return (
    <div className={`flex flex-col gap-2 bg-white p-4 md:p-5 ${PANEL}`}>
      <span className={TILE_LABEL}>Weeks together</span>
      {weeks.length > 0 && (
        <span className="flex items-baseline gap-1.5">
          <span className="text-4xl font-bold leading-none md:text-5xl">{yes}</span>
          <span className="text-sm font-bold text-black/65">of {weeks.length} {weeks.length === 1 ? "week" : "weeks"}</span>
        </span>
      )}
      {weeks.length > 0 && (
        <ul className="flex flex-wrap gap-1">
          {weeks.map(({ week, worked_together: worked }) => (
            <li
              key={week}
              title={worked ? `Week ${week}: you worked together` : `Week ${week}: no Yes`}
              className={`flex min-w-10 flex-1 items-center justify-center gap-0.5 rounded-md border-2 border-black py-1 text-xs font-bold ${worked ? "bg-green" : "bg-white"}`}
            >
              W{week}
              {worked && <Check className="h-3 w-3" aria-hidden="true" />}
              <span className="sr-only">{worked ? "you worked together" : "no Yes"}</span>
            </li>
          ))}
        </ul>
      )}
      {!partnership.ended && (
        <p className="text-sm text-black/65">The next check-in email goes out on {nextCheckIn}: did you two work together?</p>
      )}
    </div>
  );
}

function ResourcesTile({ partnership }) {
  const { count, latest } = partnership.resources;

  return (
    <Link
      href={`/partners/${partnership.id}/resources`}
      className={`flex flex-col items-start gap-2 bg-white p-4 transition-transform hover:-translate-y-0.5 md:p-5 ${PANEL}`}
    >
      <span className={`flex items-center gap-1.5 ${TILE_LABEL}`}>
        <Link2 className="h-4 w-4" />
        Resources
      </span>
      {count > 0 ? (
        <span className="flex items-baseline gap-1.5">
          <span className="text-4xl font-bold leading-none md:text-5xl">{count}</span>
          <span className="text-sm font-bold">{count === 1 ? "link" : "links"}</span>
        </span>
      ) : (
        <span className="text-lg font-bold">No links yet</span>
      )}
      {latest ? (
        <span className="max-w-full truncate text-sm text-black/65">Latest: {latest}</span>
      ) : (
        <span className="text-sm text-black/65">Docs, repos and exercises you both want to keep.</span>
      )}
      <span className="mt-auto text-sm font-bold underline">Open resources</span>
    </Link>
  );
}

function Commitments({ partnership }) {
  const rows = [
    ["You", partnership.your_commitment],
    [partnership.conversation.other.name, partnership.partner_commitment],
  ];

  return (
    <div className={`bg-white p-4 ${PANEL}`}>
      <p className="mb-2 font-bold">Committed to</p>
      <dl className="grid grid-cols-2 gap-3 text-sm">
        {rows.map(([person, commitment]) => (
          <div key={person}>
            <dt className="text-xs font-bold uppercase tracking-wide text-black/65">{person}</dt>
            <dd className="font-medium">{commitment ?? "Not said"}</dd>
          </div>
        ))}
      </dl>
    </div>
  );
}

// The Workspace overview: tiles that each open a space of their own (#241).
export default function Show({ partnership }) {
  const name = partnership.conversation.other.name;

  return (
    <WorkspaceFrame partnership={partnership} title={`You and ${name}`} back={{ href: "/partners", label: "Partners" }}>
      {partnership.ended && (
        <div className="mb-4 flex items-start gap-2 rounded-xl border-2 border-black bg-black/5 p-3 text-sm">
          <Lock className="mt-0.5 h-4 w-4 shrink-0" />
          <b>{partnership.ended_by_viewer ? "You ended this partnership." : "This partnership has ended."} You can still read it.</b>
        </div>
      )}

      <div className="mb-4 md:mb-6">
        <Goal key={partnership.goal ?? ""} partnership={partnership} />
      </div>

      <div className="grid gap-4 md:grid-cols-2 md:gap-6">
        <ChatTile partnership={partnership} />
        <ResourcesTile partnership={partnership} />
        <WeeksTile partnership={partnership} />
        <Commitments partnership={partnership} />
        {!partnership.ended && <div className="flex items-end"><EndPartnership partnership={partnership} /></div>}
      </div>
    </WorkspaceFrame>
  );
}
