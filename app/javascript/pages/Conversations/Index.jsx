import { Head, Link, router, useForm } from "@inertiajs/react";
import { useEffect, useRef, useState } from "react";
import { ArrowLeft, Check, Flag, Lock, MessagesSquare, ShieldBan, Users } from "lucide-react";
import { BlockConfirmation, Composer, Face, Messages, ReportForm, TAP_AREA } from "@/components/ConversationParts";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";

const STATUS_STYLES = {
  Reply: "bg-orange text-black",
  Talking: "bg-green text-black",
  Partners: "bg-purple text-white",
  Sent: "bg-white text-black",
  Ended: "bg-black/10 text-black/65",
};

function StatusBadge({ status }) {
  return <Badge className={`rounded-full border-black text-xs ${STATUS_STYLES[status]}`}>{status}</Badge>;
}

function ConversationList({ conversations, activeId }) {
  return (
    <>
      <h1 className="border-b-2 border-black p-4 text-xl">Conversations</h1>
      {conversations.length === 0 ? (
        <p className="p-4 text-sm text-black/65">
          Nothing here yet. <Link href="/pair_requests" className="font-bold text-purple">Find a partner search</Link> to apply to, or start your own.
        </p>
      ) : (
        <ul>
          {conversations.map((c) => (
            <li key={c.id}>
              <Link
                href={`/conversations/${c.id}`}
                className={`flex items-center gap-3 border-b-2 border-black/10 p-3 hover:bg-yellow-50 ${c.id === activeId ? "bg-purple/10" : ""}`}
              >
                <Face person={c.other} />
                <div className="min-w-0 flex-1">
                  <p className="flex items-center justify-between gap-2 text-sm font-bold">
                    <span className="truncate">{c.other.name}</span>
                    <StatusBadge status={c.status} />
                  </p>
                  <p className="flex items-center justify-between gap-2 text-xs text-black/65">
                    <span className="truncate">{c.line}</span>
                    {c.unread > 0 && (
                      <span aria-label={`${c.unread} unread`} className="shrink-0 rounded-full border-2 border-black bg-orange px-1.5 font-bold text-black">
                        {c.unread}
                      </span>
                    )}
                  </p>
                </div>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </>
  );
}

function ApplicationAnswers({ conversation }) {
  const { application, other, search, viewer_is_poster: isPoster } = conversation;
  const rows = [
    [isPoster ? "Their goal" : "Your goal", application.goal],
    ["How often", application.how_often_label],
    ["How long", application.how_long_label],
    [isPoster ? "You're looking for" : `${other.name} is looking for`, search.commitment_label],
  ];
  if (isPoster && other.level) rows.push(["Level", other.level]);

  return (
    <div className="rounded-2xl border-2 border-black bg-white p-4 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]">
      <p className="mb-3 text-xs font-bold uppercase tracking-wide text-purple">Application</p>
      <dl className="grid grid-cols-1 gap-3 text-sm sm:grid-cols-2">
        {rows.map(([label, value]) => (
          <div key={label}>
            <dt className="text-xs font-bold uppercase tracking-wide text-black/65">{label}</dt>
            <dd className="font-medium">{value}</dd>
          </div>
        ))}
        {isPoster && other.github_url && (
          <div>
            <dt className="text-xs font-bold uppercase tracking-wide text-black/65">GitHub</dt>
            <dd>
              <a href={other.github_url} target="_blank" rel="noopener noreferrer" className="font-bold text-purple underline">
                {other.github_url.replace(/^https?:\/\/(www\.)?/, "")}
              </a>
            </dd>
          </div>
        )}
      </dl>
    </div>
  );
}

function NotAMatch({ conversation }) {
  const [open, setOpen] = useState(false);
  const { data, setData, post, processing } = useForm({ reason: "" });

  if (!open) {
    return (
      <button type="button" onClick={() => setOpen(true)} className={`mt-1 text-xs font-bold text-black/65 hover:text-black md:mt-2 ${TAP_AREA}`}>
        Not a match
      </button>
    );
  }

  return (
    <form
      className="mt-3 rounded-xl border-2 border-black bg-yellow-50 p-3"
      onSubmit={(e) => {
        e.preventDefault();
        post(`/conversations/${conversation.id}/not_a_match`, { preserveScroll: true });
      }}
    >
      <p className="text-sm font-bold">End this conversation?</p>
      <p className="mb-2 text-xs text-black/65">We'll tell {conversation.other.name} kindly. Neither of you can write here afterwards.</p>
      <Label htmlFor="not_a_match_reason" className="mb-1 block text-xs">Why? (optional, only we see this)</Label>
      <Textarea id="not_a_match_reason" rows={2} value={data.reason} onChange={(e) => setData("reason", e.target.value)} />
      <div className="mt-2 flex gap-2">
        <Button type="submit" size="sm" disabled={processing}>End conversation</Button>
        <Button type="button" size="sm" variant="neutral" onClick={() => setOpen(false)}>Keep talking</Button>
      </div>
    </form>
  );
}

function ProposalBanner({ conversation, onPost }) {
  const name = conversation.other.name;

  if (conversation.partners) {
    return (
      <div className="flex items-center gap-2 border-b-2 border-black bg-green/30 p-3 text-sm font-bold">
        <Users className="h-4 w-4 shrink-0" />
        You and {name} are partners.
        {conversation.partnership_id && (
          <Link href={`/partners/${conversation.partnership_id}`} className="ml-auto text-purple underline">Open your Workspace</Link>
        )}
      </div>
    );
  }
  if (conversation.proposal === "incoming") {
    return (
      <div className="flex flex-wrap items-center justify-between gap-2 border-b-2 border-black bg-green/30 p-3">
        <b className="text-sm">{name} wants to become partners.</b>
        <span className="flex gap-2">
          <Button size="sm" onClick={() => onPost("accept_proposal")}><Check />Accept</Button>
          <Button size="sm" variant="neutral" onClick={() => onPost("decline_proposal")}>Not yet</Button>
        </span>
      </div>
    );
  }
  if (conversation.proposal === "waiting") {
    return (
      <div className="border-b-2 border-black bg-yellow-100 p-3 text-sm font-bold">
        You asked to become partners. Waiting for {name}, and you can keep talking.
      </div>
    );
  }
  if (conversation.proposal === "declined") {
    return (
      <div className="border-b-2 border-black bg-yellow-100 p-3 text-sm font-bold">
        {name} said not yet. You can keep talking, and ask again when it feels right.
      </div>
    );
  }
  return null;
}

function Thread({ conversation }) {
  const { other, search, chat_open: chatOpen, ended, can_send: canSend, application } = conversation;
  const [showApplication, setShowApplication] = useState(false);
  const [confirmingBlock, setConfirmingBlock] = useState(false);
  const [reporting, setReporting] = useState(false);
  const scroller = useRef(null);

  useEffect(() => {
    if (scroller.current) scroller.current.scrollTop = scroller.current.scrollHeight;
  }, [conversation.id, conversation.messages.length]);

  const pinned = application && !chatOpen && !ended;
  const postProposal = (action) => router.post(`/conversations/${conversation.id}/${action}`, {}, { preserveScroll: true });

  return (
    <>
      <header className="flex flex-wrap items-center justify-between gap-2 border-b-2 border-black bg-white p-3">
        <div className="flex min-w-0 items-center gap-3">
          <Link href="/conversations" aria-label="All conversations" className="-ml-2 flex h-11 w-11 shrink-0 items-center justify-center md:hidden">
            <ArrowLeft className="h-5 w-5" />
          </Link>
          <Face person={other} />
          <div className="min-w-0">
            <p className="font-bold">{other.name}</p>
            <p className="truncate text-xs text-black/65">{search.subject}</p>
          </div>
        </div>
        <div className="flex items-center gap-3">
          <button type="button" onClick={() => setReporting(true)} className={`gap-1 text-xs font-bold text-black/65 hover:text-black ${TAP_AREA}`}>
            <Flag className="h-3.5 w-3.5" />
            Report
          </button>
          <button type="button" onClick={() => setConfirmingBlock(true)} className={`gap-1 text-xs font-bold text-black/65 hover:text-black ${TAP_AREA}`}>
            <ShieldBan className="h-3.5 w-3.5" />
            Block
          </button>
          <StatusBadge status={conversation.status} />
          {conversation.can_propose && (
            <Button size="sm" onClick={() => postProposal("propose")}><Users />Become partners</Button>
          )}
        </div>
      </header>

      <ProposalBanner conversation={conversation} onPost={postProposal} />

      {reporting && <ReportForm conversation={conversation} onDone={() => setReporting(false)} />}
      {confirmingBlock && <BlockConfirmation conversation={conversation} onCancel={() => setConfirmingBlock(false)} />}

      <div ref={scroller} className="flex-1 overflow-y-auto p-4">
        {application && !pinned && (
          <button type="button" onClick={() => setShowApplication(!showApplication)} className={`mb-3 text-xs font-bold text-purple underline ${TAP_AREA}`}>
            {showApplication ? "Hide application" : "Show application"}
          </button>
        )}
        {(pinned || (application && showApplication)) && (
          <div className="mb-4">
            <ApplicationAnswers conversation={conversation} />
          </div>
        )}
        <Messages messages={conversation.messages} dim={ended} />
      </div>

      <div className="border-t-2 border-black bg-white p-3">
        {ended ? (
          <div className="flex items-start gap-2 rounded-xl border-2 border-black bg-black/5 p-3 text-sm">
            <Lock className="mt-0.5 h-4 w-4 shrink-0" />
            <span>
              <b>{conversation.search_filled ? "This search has found its partner, so this chat has ended." : conversation.ended_by_viewer ? "You ended this conversation." : "This conversation has ended."}</b> You can still read it.{" "}
              <Link href="/pair_requests" className="font-bold underline">See open partner searches</Link>
            </span>
          </div>
        ) : (
          <>
            {canSend ? (
              <Composer key={conversation.id} conversation={conversation} />
            ) : (
              <p className="rounded-xl border-2 border-black bg-yellow-50 p-3 text-sm font-bold">
                You can write more once {other.name} replies.
              </p>
            )}
            {!conversation.partners && <NotAMatch key={`end-${conversation.id}`} conversation={conversation} />}
          </>
        )}
      </div>
    </>
  );
}

export default function Index({ conversations, conversation }) {
  return (
    <div className="grid h-[calc(100dvh-4rem)] grid-cols-1 md:h-screen md:grid-cols-[300px_minmax(0,1fr)]">
      <Head title="Conversations" />

      {/* On phones the list opens first, then a thread replaces it. */}
      <aside className={`overflow-y-auto border-r-2 border-black bg-white ${conversation ? "hidden md:block" : ""}`}>
        <ConversationList conversations={conversations} activeId={conversation?.id} />
      </aside>

      <section className={`min-h-0 flex-col ${conversation ? "flex" : "hidden md:flex"}`}>
        {conversation ? (
          <Thread conversation={conversation} />
        ) : (
          <div className="flex flex-1 flex-col items-center justify-center gap-2 text-black/65">
            <MessagesSquare className="h-8 w-8" />
            <p className="font-bold">Pick a conversation</p>
          </div>
        )}
      </section>
    </div>
  );
}
