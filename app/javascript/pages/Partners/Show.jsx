import { Head, Link, useForm } from "@inertiajs/react";
import { useEffect, useRef, useState } from "react";
import { ArrowLeft, Check, Flag, Lock, Plus, ShieldBan, Target } from "lucide-react";
import { BlockConfirmation, Composer, Messages, ReportForm, TAP_AREA } from "@/components/ConversationParts";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";

function GoalForm({ partnership, onDone }) {
  const { data, setData, patch, processing, errors } = useForm({ goal: partnership.goal ?? "" });

  const save = (e) => {
    e.preventDefault();
    patch(`/partners/${partnership.id}`, { preserveScroll: true, onSuccess: onDone });
  };

  return (
    <form onSubmit={save} className="rounded-2xl border-2 border-black bg-white p-5 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]">
      <Label htmlFor="partnership_goal" className="mb-1 block">What are you working towards? (optional)</Label>
      <Textarea id="partnership_goal" rows={2} autoFocus value={data.goal} onChange={(e) => setData("goal", e.target.value)} />
      {errors.goal && <div className="mt-1 text-sm font-bold text-red">{errors.goal}</div>}
      <p className="mt-1 text-xs text-black/65">You can both change this. Leave it empty to remove it.</p>
      <div className="mt-3 flex gap-2">
        <Button type="submit" size="sm" disabled={processing}>Save goal</Button>
        <Button type="button" size="sm" variant="neutral" onClick={onDone}>Cancel</Button>
      </div>
    </form>
  );
}

function Goal({ partnership }) {
  const [editing, setEditing] = useState(false);
  const { goal, ended } = partnership;

  if (editing) return <GoalForm partnership={partnership} onDone={() => setEditing(false)} />;

  if (!goal) {
    if (ended) return null;

    return (
      <button
        type="button"
        onClick={() => setEditing(true)}
        className="flex min-h-11 w-full items-center gap-2 rounded-2xl border-2 border-dashed border-black px-4 py-2 text-sm font-bold hover:bg-white md:p-4"
      >
        <Plus className="h-4 w-4" />
        Add a shared goal (optional)
      </button>
    );
  }

  return (
    <div className="flex items-center gap-3 rounded-2xl border-2 border-black bg-purple px-3 py-2 text-white shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] md:items-start md:p-5">
      <Target className="h-5 w-5 shrink-0 md:mt-1 md:h-6 md:w-6" />
      <div className="min-w-0 flex-1">
        <p className="hidden text-xs font-bold uppercase tracking-wide text-white md:block">Working towards</p>
        {/* One line on phones, so the chat stays in view. The whole goal shows when editing. */}
        <p className="truncate text-sm font-bold md:whitespace-pre-wrap md:break-words md:text-xl">{goal}</p>
      </div>
      {!ended && (
        <button type="button" onClick={() => setEditing(true)} className={`shrink-0 text-xs font-bold text-white underline ${TAP_AREA}`}>
          Edit
        </button>
      )}
    </div>
  );
}

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

function CheckIns({ partnership }) {
  const nextCheckIn = new Intl.DateTimeFormat(undefined, { weekday: "long", day: "numeric", month: "long" }).format(new Date(partnership.next_check_in_at));

  return (
    <div className="rounded-2xl border-2 border-black bg-white p-4 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]">
      <p className="mb-2 font-bold">Check-ins</p>
      {!partnership.ended && (
        <p className="text-sm text-black/65">The next check-in email goes out on {nextCheckIn}: did you two work together?</p>
      )}
      {partnership.weeks.length > 0 && (
        <ul className="mt-2 flex flex-wrap gap-1">
          {partnership.weeks.map(({ week, worked_together: worked }) => (
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
      {partnership.weeks.length > 0 && <p className="mt-2 text-xs text-black/65">A tick means you worked together that week.</p>}
    </div>
  );
}

function Commitments({ partnership }) {
  const rows = [
    ["You", partnership.your_commitment],
    [partnership.conversation.other.name, partnership.partner_commitment],
  ];

  return (
    <div className="rounded-2xl border-2 border-black bg-white p-4 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]">
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

export default function Show({ partnership }) {
  const conversation = partnership.conversation;
  const [reporting, setReporting] = useState(false);
  const [confirmingBlock, setConfirmingBlock] = useState(false);
  const scroller = useRef(null);

  useEffect(() => {
    if (scroller.current) scroller.current.scrollTop = scroller.current.scrollHeight;
  }, [conversation.messages.length]);

  return (
    <div className="mx-auto w-full max-w-6xl px-4 pb-16 pt-2 md:px-8 md:pt-8">
      <Head title={`You and ${conversation.other.name}`} />

      <div className="mb-2 flex flex-wrap items-center justify-between gap-x-2 md:mb-5">
        <div className="min-w-0">
          <Link href="/partners" className={`gap-1 text-xs font-bold text-black/65 hover:text-black md:mb-2 ${TAP_AREA}`}>
            <ArrowLeft className="h-3.5 w-3.5" />
            Partners
          </Link>
          <p className="hidden text-xs font-bold uppercase tracking-widest text-purple md:block">Workspace</p>
          <h1 className="text-2xl md:text-3xl">You and {conversation.other.name}</h1>
          <p className="mt-1 hidden text-sm text-black/65 md:block">{conversation.search.subject}</p>
        </div>
        <span className="flex items-center gap-3 text-xs font-bold text-black/65">
          <button type="button" onClick={() => setReporting(true)} className={`gap-1 hover:text-black ${TAP_AREA}`}>
            <Flag className="h-3.5 w-3.5" />
            Report
          </button>
          {!partnership.ended && (
            <button type="button" onClick={() => setConfirmingBlock(true)} className={`gap-1 hover:text-black ${TAP_AREA}`}>
              <ShieldBan className="h-3.5 w-3.5" />
              Block
            </button>
          )}
        </span>
      </div>

      {(reporting || confirmingBlock) && (
        <div className="mb-5 overflow-hidden rounded-2xl border-2 border-black">
          {reporting && <ReportForm conversation={conversation} onDone={() => setReporting(false)} />}
          {confirmingBlock && (
            <BlockConfirmation
              conversation={conversation}
              onCancel={() => setConfirmingBlock(false)}
              consequence="This ends your partnership and your conversations, and neither of you will see or apply to the other's partner searches."
            />
          )}
        </div>
      )}

      <div className="mb-3 md:mb-6">
        <Goal key={partnership.goal ?? ""} partnership={partnership} />
      </div>

      <div className="grid items-start gap-6 lg:grid-cols-[minmax(0,1fr)_320px]">
        <div className="flex h-[calc(100dvh-14rem)] min-h-[20rem] flex-col rounded-2xl border-2 border-black bg-white p-3 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] md:p-4 lg:h-[60vh]">
          <p className="mb-3 hidden font-bold md:block">Chat</p>
          <div ref={scroller} className="min-h-0 flex-1 overflow-y-auto">
            <Messages messages={conversation.messages} dim={partnership.ended} />
          </div>
          <div className="pt-3">
            {conversation.can_send ? (
              <Composer conversation={conversation} />
            ) : (
              <div className="flex items-start gap-2 rounded-xl border-2 border-black bg-black/5 p-3 text-sm">
                <Lock className="mt-0.5 h-4 w-4 shrink-0" />
                <b>{partnership.ended_by_viewer ? "You ended this partnership." : "This partnership has ended."} You can still read it.</b>
              </div>
            )}
          </div>
        </div>

        <div className="flex flex-col gap-6">
          <CheckIns partnership={partnership} />
          <Commitments partnership={partnership} />
          {!partnership.ended && <EndPartnership partnership={partnership} />}
        </div>
      </div>
    </div>
  );
}
