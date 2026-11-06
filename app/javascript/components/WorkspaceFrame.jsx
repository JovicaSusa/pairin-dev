import { Head, Link, useForm } from "@inertiajs/react";
import { useState } from "react";
import { ArrowLeft, Flag, Plus, ShieldBan, Target } from "lucide-react";
import { BlockConfirmation, ReportForm, TAP_AREA } from "@/components/ConversationParts";
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

export function Goal({ partnership }) {
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
        <p className="break-words text-sm font-bold md:whitespace-pre-wrap md:text-xl">{goal}</p>
      </div>
      {!ended && (
        <button type="button" onClick={() => setEditing(true)} className={`shrink-0 text-xs font-bold text-white underline ${TAP_AREA}`}>
          Edit
        </button>
      )}
    </div>
  );
}

// The header every Workspace page shares: a way back, the title, and Report and Block.
export default function WorkspaceFrame({ partnership, title, back, children }) {
  const conversation = partnership.conversation;
  const [reporting, setReporting] = useState(false);
  const [confirmingBlock, setConfirmingBlock] = useState(false);

  return (
    <div className="mx-auto w-full max-w-6xl px-4 pb-16 pt-2 md:px-8 md:pt-8">
      <Head title={title} />

      <div className="mb-2 flex flex-wrap items-center justify-between gap-x-2 md:mb-5">
        <div className="min-w-0">
          <Link href={back.href} className={`gap-1 text-xs font-bold text-black/65 hover:text-black md:mb-2 ${TAP_AREA}`}>
            <ArrowLeft className="h-3.5 w-3.5" />
            {back.label}
          </Link>
          <p className="hidden text-xs font-bold uppercase tracking-widest text-purple md:block">Workspace</p>
          <h1 className="text-2xl md:text-3xl">{title}</h1>
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

      {children}
    </div>
  );
}
