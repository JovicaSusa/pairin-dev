// PROTOTYPE ONLY (throwaway, branch prototype/workspace-sessions-resources). Never merge.
// Question (#226, #186): how do sessions (propose form + every state) and shared resources fit the Workspace?
// Three variants on the real /partners/:id page, switchable via ?variant=A|B|C, plus ?screen=full|empty|ended.
// All session/resource data is stubbed and lives in memory. Nothing is saved.
import { useMemo, useState } from "react";
import { router } from "@inertiajs/react";
import { CalendarClock, CalendarPlus, Check, Clock, ExternalLink, Link2, Lock, Plus, Trash2, Video, X } from "lucide-react";
import { Composer, Messages } from "@/components/ConversationParts";
import PrototypeSwitcher from "@/components/PrototypeSwitcher";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

const VARIANTS = [
  { key: "A", name: "Side cards" },
  { key: "B", name: "In the chat" },
  { key: "C", name: "Tabs" },
];
const SCREENS = [
  { key: "full", name: "Every state" },
  { key: "empty", name: "Nothing yet" },
  { key: "ended", name: "Ended" },
];

const PANEL = "rounded-2xl border-2 border-black bg-white shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]";
const PARTNER_TZ = "Europe/London"; // stub: the real page would know the partner's timezone
const HOUR = 3600 * 1000;
const DAY = 24 * HOUR;

// ---------- stub data + state ----------

function at(daysFromNow, hour, minute = 0) {
  const d = new Date(Date.now() + daysFromNow * DAY);
  d.setHours(hour, minute, 0, 0);
  return d;
}

function seed(screen) {
  if (screen === "empty") return { sessions: [], resources: [] };

  const sessions = [
    { id: 1, start: at(1, 18), minutes: 60, link: "https://meet.google.com/abc-defg-hij", proposedBy: "partner", status: "confirmed" },
    { id: 2, start: at(3, 19, 30), minutes: 90, link: "", proposedBy: "partner", status: "proposed" },
    { id: 3, start: at(5, 8), minutes: 45, link: "https://zoom.us/j/123", proposedBy: "you", status: "proposed" },
    { id: 4, start: at(6, 20), minutes: 60, link: "", proposedBy: "you", status: "declined" },
    { id: 5, start: at(2, 12), minutes: 60, link: "", proposedBy: "partner", status: "cancelled", cancelledBy: "partner" },
    { id: 6, start: at(-1, 18), minutes: 60, link: "", proposedBy: "partner", status: "proposed" }, // passed unanswered = expired
    { id: 7, start: at(-3, 18), minutes: 60, link: "https://meet.google.com/xyz", proposedBy: "you", status: "confirmed" }, // past
    { id: 8, start: at(-8, 19), minutes: 90, link: "", proposedBy: "partner", status: "confirmed" }, // past
  ];
  const resources = [
    { id: 1, url: "https://guides.rubyonrails.org/active_record_basics.html", note: "Chapter we're reading this week", addedBy: "partner" },
    { id: 2, url: "https://github.com/sam/todo-app", note: "Our practice repo", addedBy: "you" },
    { id: 3, url: "https://exercism.org/tracks/ruby", note: "", addedBy: "partner" },
  ];

  if (screen === "ended") {
    sessions.forEach((s) => {
      if (s.start > new Date() && ["proposed", "confirmed"].includes(s.status)) s.status = "cancelled";
    });
  }
  return { sessions, resources };
}

// What a person sees: the stored status, plus "expired" and "past" worked out from the time.
function stateOf(s) {
  const now = new Date();
  const end = new Date(s.start.getTime() + s.minutes * 60000);
  if (s.status === "proposed" && s.start < now) return "expired";
  if (s.status === "confirmed" && end < now) return "past";
  return s.status;
}

function useWorkspaceStub(screen) {
  const [data, setData] = useState(() => seed(screen));
  const setSessionStatus = (id, status, extra = {}) =>
    setData((d) => ({ ...d, sessions: d.sessions.map((s) => (s.id === id ? { ...s, status, ...extra } : s)) }));

  const sessions = useMemo(() => {
    const now = new Date();
    const list = data.sessions.map((s) => ({ ...s, state: stateOf(s) }));
    const upcoming = list.filter((s) => s.start >= now).sort((a, b) => a.start - b.start);
    const past = list.filter((s) => s.start < now).sort((a, b) => b.start - a.start);
    const next = upcoming.find((s) => s.state === "confirmed");
    const waitingOnYou = upcoming.filter((s) => s.state === "proposed" && s.proposedBy === "partner");
    return { upcoming, past, next, waitingOnYou };
  }, [data.sessions]);

  return {
    sessions,
    resources: data.resources,
    propose: ({ date, time, minutes, link }) => {
      const start = new Date(`${date}T${time}`);
      setData((d) => ({ ...d, sessions: [...d.sessions, { id: Date.now(), start, minutes: Number(minutes), link, proposedBy: "you", status: "proposed" }] }));
    },
    confirm: (id) => setSessionStatus(id, "confirmed"),
    decline: (id) => setSessionStatus(id, "declined"),
    withdraw: (id) => setSessionStatus(id, "withdrawn"),
    cancel: (id) => setSessionStatus(id, "cancelled", { cancelledBy: "you" }),
    addResource: ({ url, note }) => setData((d) => ({ ...d, resources: [{ id: Date.now(), url, note, addedBy: "you" }, ...d.resources] })),
    removeResource: (id) => setData((d) => ({ ...d, resources: d.resources.filter((r) => r.id !== id) })),
  };
}

// ---------- small shared bits (layout differs per variant) ----------

function tzName(date, timeZone) {
  return new Intl.DateTimeFormat(undefined, { timeZone, timeZoneName: "short" }).formatToParts(date).find((p) => p.type === "timeZoneName")?.value;
}

function when(s, timeZone) {
  const end = new Date(s.start.getTime() + s.minutes * 60000);
  const day = new Intl.DateTimeFormat(undefined, { timeZone, weekday: "short", day: "numeric", month: "short" }).format(s.start);
  const time = (d) => new Intl.DateTimeFormat(undefined, { timeZone, hour: "2-digit", minute: "2-digit", hour12: false }).format(d);
  return { day, range: `${time(s.start)}–${time(end)}`, tz: tzName(s.start, timeZone) };
}

function When({ s, partnerName, compact = false }) {
  const mine = when(s);
  const theirs = when(s, PARTNER_TZ);
  const differs = mine.tz !== theirs.tz;
  return (
    <div className="min-w-0">
      <p className={`font-bold ${compact ? "text-sm" : ""}`}>
        {mine.day} · {mine.range} <span className="text-xs font-bold text-black/65">{mine.tz}</span>
      </p>
      {differs && <p className="text-xs text-black/65">{theirs.range} {theirs.tz} for {partnerName}</p>}
    </div>
  );
}

const STATE_LABEL = {
  proposed: "Proposed",
  confirmed: "Confirmed",
  declined: "Declined",
  withdrawn: "Withdrawn",
  cancelled: "Cancelled",
  expired: "Expired",
  past: "Done",
};
const STATE_STYLE = {
  proposed: "bg-yellow-50",
  confirmed: "bg-green",
  declined: "bg-black/5 text-black/65 line-through",
  withdrawn: "bg-black/5 text-black/65 line-through",
  cancelled: "bg-black/5 text-black/65 line-through",
  expired: "bg-black/5 text-black/65",
  past: "bg-white",
};

function StateBadge({ s }) {
  return <span className={`inline-flex shrink-0 items-center rounded-full border-2 border-black px-2 py-0.5 text-xs font-bold ${STATE_STYLE[s.state]}`}>{STATE_LABEL[s.state]}</span>;
}

function stateNote(s, partnerName) {
  if (s.state === "proposed") return s.proposedBy === "you" ? `Waiting for ${partnerName} to confirm` : `${partnerName} proposed this`;
  if (s.state === "declined") return s.proposedBy === "you" ? `${partnerName} declined` : "You declined";
  if (s.state === "withdrawn") return "You withdrew this";
  if (s.state === "cancelled") return s.cancelledBy === "you" ? "You cancelled" : s.cancelledBy === "partner" ? `${partnerName} cancelled` : "Cancelled when the partnership ended";
  if (s.state === "expired") return "Nobody answered before it started";
  return null;
}

function SessionActions({ s, stub, ended, size = "sm" }) {
  if (ended) return null;
  if (s.state === "proposed" && s.proposedBy === "partner")
    return (
      <div className="flex flex-wrap gap-2">
        <Button size={size} onClick={() => stub.confirm(s.id)}><Check className="h-4 w-4" />Confirm</Button>
        <Button size={size} variant="neutral" onClick={() => stub.decline(s.id)}>Decline</Button>
      </div>
    );
  if (s.state === "proposed") return <Button size={size} variant="neutral" onClick={() => stub.withdraw(s.id)}>Withdraw</Button>;
  if (s.state === "confirmed")
    return (
      <div className="flex flex-wrap gap-2">
        {s.link && (
          <Button asChild size={size}>
            <a href={s.link} target="_blank" rel="noopener noreferrer"><Video className="h-4 w-4" />Join call</a>
          </Button>
        )}
        <Button size={size} variant="neutral" onClick={() => alert("Prototype: downloads an .ics file (#230)")}><CalendarPlus className="h-4 w-4" />Calendar</Button>
        <Button size={size} variant="neutral" onClick={() => stub.cancel(s.id)}>Cancel</Button>
      </div>
    );
  return null;
}

const LENGTHS = [30, 45, 60, 90, 120];

function ProposeForm({ stub, onDone, partnerName, columns = false }) {
  const tomorrow = new Date(Date.now() + DAY).toISOString().slice(0, 10);
  const [form, setForm] = useState({ date: tomorrow, time: "18:00", minutes: "60", link: "" });
  const [error, setError] = useState(null);
  const set = (k) => (e) => setForm({ ...form, [k]: e.target.value });

  const submit = (e) => {
    e.preventDefault();
    if (new Date(`${form.date}T${form.time}`) < new Date()) return setError("Pick a time in the future.");
    if (form.link && !/^https?:\/\//.test(form.link)) return setError("Call links start with http:// or https://");
    stub.propose(form);
    onDone?.();
  };

  return (
    <form onSubmit={submit} className="flex flex-col gap-3">
      <div className={`grid gap-3 ${columns ? "sm:grid-cols-3" : "grid-cols-2"}`}>
        <div className={columns ? "" : "col-span-2"}>
          <Label htmlFor="p_date" className="mb-1 block text-xs">Date</Label>
          <Input id="p_date" type="date" value={form.date} min={new Date().toISOString().slice(0, 10)} onChange={set("date")} className="bg-white" />
        </div>
        <div>
          <Label htmlFor="p_time" className="mb-1 block text-xs">Start ({tzName(new Date())})</Label>
          <Input id="p_time" type="time" value={form.time} onChange={set("time")} className="bg-white" />
        </div>
        <div>
          <Label htmlFor="p_len" className="mb-1 block text-xs">Length</Label>
          <select id="p_len" value={form.minutes} onChange={set("minutes")} className="h-10 w-full rounded-base border-2 border-black bg-white px-2 text-sm">
            {LENGTHS.map((m) => <option key={m} value={m}>{m < 60 ? `${m} min` : `${m / 60} h`}</option>)}
          </select>
        </div>
      </div>
      <div>
        <Label htmlFor="p_link" className="mb-1 block text-xs">Call link (optional)</Label>
        <Input id="p_link" type="url" placeholder="https://meet.google.com/…" value={form.link} onChange={set("link")} className="bg-white" />
      </div>
      {error && <p className="text-sm font-bold text-red">{error}</p>}
      <p className="text-xs text-black/65">{partnerName} gets an email and confirms it here.</p>
      <div className="flex gap-2">
        <Button type="submit" size="sm">Propose session</Button>
        {onDone && <Button type="button" size="sm" variant="neutral" onClick={onDone}>Cancel</Button>}
      </div>
    </form>
  );
}

function host(url) {
  try { return new URL(url).host.replace(/^www\./, ""); } catch { return url; }
}

function AddLinkForm({ stub, onDone }) {
  const [url, setUrl] = useState("");
  const [note, setNote] = useState("");
  const [error, setError] = useState(null);
  const submit = (e) => {
    e.preventDefault();
    if (!/^https?:\/\/\S+$/.test(url)) return setError("Links start with http:// or https://");
    stub.addResource({ url, note });
    setUrl(""); setNote(""); setError(null);
    onDone?.();
  };
  return (
    <form onSubmit={submit} className="flex flex-col gap-2">
      <Input aria-label="Link" type="url" placeholder="https://…" value={url} onChange={(e) => setUrl(e.target.value)} className="bg-white" autoFocus />
      <Input aria-label="Note (optional)" placeholder="Note (optional)" value={note} onChange={(e) => setNote(e.target.value)} className="bg-white" />
      {error && <p className="text-sm font-bold text-red">{error}</p>}
      <div className="flex gap-2">
        <Button type="submit" size="sm">Add link</Button>
        {onDone && <Button type="button" size="sm" variant="neutral" onClick={onDone}>Cancel</Button>}
      </div>
    </form>
  );
}

function ResourceLine({ r, stub, ended, partnerName }) {
  return (
    <li className="flex items-start gap-2">
      <Link2 className="mt-1 h-4 w-4 shrink-0" />
      <div className="min-w-0 flex-1">
        <a href={r.url} target="_blank" rel="noopener noreferrer" className="block truncate text-sm font-bold underline">{host(r.url)}</a>
        {r.note && <p className="text-xs text-black/65">{r.note}</p>}
        <p className="text-xs text-black/50">Added by {r.addedBy === "you" ? "you" : partnerName}</p>
      </div>
      {!ended && (
        <button type="button" aria-label="Remove link" onClick={() => stub.removeResource(r.id)} className="inline-flex min-h-11 min-w-11 items-center justify-center text-black/50 hover:text-black md:min-h-0 md:min-w-0">
          <Trash2 className="h-4 w-4" />
        </button>
      )}
    </li>
  );
}

function ChatPanel({ partnership, children, className = "" }) {
  const conversation = partnership.conversation;
  return (
    <div className={`flex h-[calc(100dvh-14rem)] min-h-[20rem] flex-col p-3 md:p-4 lg:h-[60vh] ${PANEL} ${className}`}>
      <p className="mb-3 hidden font-bold md:block">Chat</p>
      <div className="min-h-0 flex-1 overflow-y-auto">
        <Messages messages={conversation.messages} dim={partnership.ended} />
        {children}
      </div>
      <div className="pt-3">
        {conversation.can_send ? <Composer conversation={conversation} /> : (
          <div className="flex items-start gap-2 rounded-xl border-2 border-black bg-black/5 p-3 text-sm">
            <Lock className="mt-0.5 h-4 w-4 shrink-0" />
            <b>This partnership has ended. You can still read it.</b>
          </div>
        )}
      </div>
    </div>
  );
}

// ---------- Variant A: everything lives in side-column cards ----------

function SessionRow({ s, stub, ended, partnerName }) {
  const note = stateNote(s, partnerName);
  const dead = ["declined", "withdrawn", "cancelled", "expired"].includes(s.state);
  return (
    <li className={`flex flex-col gap-2 border-t-2 border-black/10 py-3 first:border-t-0 first:pt-0 ${dead ? "opacity-70" : ""}`}>
      <div className="flex items-start justify-between gap-2">
        <When s={s} partnerName={partnerName} compact />
        <StateBadge s={s} />
      </div>
      {note && <p className="text-xs text-black/65">{note}</p>}
      <SessionActions s={s} stub={stub} ended={ended} />
    </li>
  );
}

function VariantA({ partnership, stub, slots }) {
  const name = partnership.conversation.other.name;
  const { upcoming, past, next, waitingOnYou } = stub.sessions;
  const [proposing, setProposing] = useState(false);
  const [addingLink, setAddingLink] = useState(false);
  const [showPast, setShowPast] = useState(false);
  const ended = partnership.ended;

  const sessionsCard = (
    <div className={`p-4 ${PANEL}`}>
      <div className="mb-3 flex items-center justify-between">
        <p className="flex items-center gap-1.5 font-bold"><CalendarClock className="h-4 w-4" />Sessions</p>
        {!ended && !proposing && <Button size="sm" variant="neutral" onClick={() => setProposing(true)}><Plus className="h-4 w-4" />Propose</Button>}
      </div>
      {proposing && <div className="mb-4 rounded-xl border-2 border-black bg-yellow-50 p-3"><ProposeForm stub={stub} partnerName={name} onDone={() => setProposing(false)} /></div>}
      {upcoming.length === 0 && !proposing && <p className="text-sm text-black/65">No sessions planned. {ended ? "" : `Propose a time and ${name} can confirm it.`}</p>}
      <ul>{upcoming.map((s) => <SessionRow key={s.id} s={s} stub={stub} ended={ended} partnerName={name} />)}</ul>
      {past.length > 0 && (
        <>
          <button type="button" onClick={() => setShowPast(!showPast)} className="mt-2 text-xs font-bold underline">{showPast ? "Hide" : "Show"} past ({past.length})</button>
          {showPast && <ul className="mt-3">{past.map((s) => <SessionRow key={s.id} s={s} stub={stub} ended={ended} partnerName={name} />)}</ul>}
        </>
      )}
    </div>
  );

  const resourcesCard = (
    <div className={`p-4 ${PANEL}`}>
      <div className="mb-3 flex items-center justify-between">
        <p className="flex items-center gap-1.5 font-bold"><Link2 className="h-4 w-4" />Resources</p>
        {!ended && !addingLink && <Button size="sm" variant="neutral" onClick={() => setAddingLink(true)}><Plus className="h-4 w-4" />Add a link</Button>}
      </div>
      {addingLink && <div className="mb-3"><AddLinkForm stub={stub} onDone={() => setAddingLink(false)} /></div>}
      {stub.resources.length === 0 && !addingLink && <p className="text-sm text-black/65">Links you both want to keep: docs, repos, exercises.</p>}
      <ul className="flex flex-col gap-3">{stub.resources.map((r) => <ResourceLine key={r.id} r={r} stub={stub} ended={ended} partnerName={name} />)}</ul>
    </div>
  );

  // On phones the side column falls below the chat, so the one thing that needs an answer is lifted above it.
  const callout = waitingOnYou[0] ?? next;

  return (
    <>
      {callout && (
        <div className={`mb-3 flex flex-col gap-2 p-3 lg:hidden ${PANEL} ${callout.state === "confirmed" ? "bg-green/20" : "bg-yellow-50"}`}>
          <p className="text-xs font-bold uppercase tracking-wide">{callout.state === "confirmed" ? "Next session" : `${name} proposed a session`}</p>
          <When s={callout} partnerName={name} compact />
          <SessionActions s={callout} stub={stub} ended={ended} />
        </div>
      )}
      <div className="grid items-start gap-6 lg:grid-cols-[minmax(0,1fr)_340px]">
        <ChatPanel partnership={partnership} />
        <div className="flex flex-col gap-6">
          {sessionsCard}
          {resourcesCard}
          {slots.checkIns}
          {slots.commitments}
          {slots.end}
        </div>
      </div>
    </>
  );
}

// ---------- Variant B: sessions and links happen in the conversation ----------

function SessionEvent({ s, stub, ended, partnerName }) {
  const note = stateNote(s, partnerName);
  return (
    <div className={`mx-auto my-3 w-full max-w-md rounded-xl border-2 border-black p-3 ${s.state === "proposed" ? "bg-yellow-50" : s.state === "confirmed" ? "bg-green/20" : "bg-black/5"}`}>
      <div className="mb-1 flex items-center justify-between gap-2">
        <p className="flex items-center gap-1.5 text-xs font-bold uppercase tracking-wide"><CalendarClock className="h-3.5 w-3.5" />{s.proposedBy === "you" ? "You" : partnerName} proposed a session</p>
        <StateBadge s={s} />
      </div>
      <When s={s} partnerName={partnerName} compact />
      {s.link && <p className="mt-1 truncate text-xs"><Video className="mr-1 inline h-3 w-3" />{host(s.link)}</p>}
      {note && s.state !== "proposed" && <p className="mt-1 text-xs text-black/65">{note}</p>}
      <div className="mt-2"><SessionActions s={s} stub={stub} ended={ended} /></div>
    </div>
  );
}

function LinkEvent({ r, partnerName }) {
  return (
    <div className={`my-3 flex flex-col ${r.addedBy === "you" ? "items-end" : "items-start"}`}>
      <a href={r.url} target="_blank" rel="noopener noreferrer" className="max-w-[85%] rounded-2xl border-2 border-black bg-white px-3 py-2 text-sm">
        <span className="flex items-center gap-1 font-bold underline"><Link2 className="h-3.5 w-3.5" />{host(r.url)}<ExternalLink className="h-3 w-3" /></span>
        {r.note && <span className="block text-xs text-black/65">{r.note}</span>}
        <span className="block text-xs text-black/50">Saved to Resources by {r.addedBy === "you" ? "you" : partnerName}</span>
      </a>
    </div>
  );
}

function VariantB({ partnership, stub, slots }) {
  const name = partnership.conversation.other.name;
  const { upcoming, past, next, waitingOnYou } = stub.sessions;
  const [tool, setTool] = useState(null); // "session" | "link" | null
  const [allOpen, setAllOpen] = useState(false);
  const ended = partnership.ended;
  const events = [...past].reverse().concat(upcoming); // oldest first, like the chat

  return (
    <>
      {/* Pinned bar: the next confirmed session, or what needs an answer. Always above the chat. */}
      <div className={`mb-3 flex flex-col gap-3 p-3 md:flex-row md:items-center md:justify-between md:p-4 ${PANEL} ${next ? "bg-green/20" : ""}`}>
        <div className="flex items-start gap-3">
          <Clock className="mt-0.5 h-5 w-5 shrink-0" />
          {next ? (
            <div>
              <p className="text-xs font-bold uppercase tracking-wide">Next session</p>
              <When s={next} partnerName={name} />
            </div>
          ) : (
            <p className="text-sm font-bold">No session planned yet.</p>
          )}
        </div>
        <div className="flex flex-wrap items-center gap-2">
          {next && <SessionActions s={next} stub={stub} ended={ended} />}
          {waitingOnYou.length > 0 && <span className="rounded-full border-2 border-black bg-yellow-50 px-2 py-0.5 text-xs font-bold">{waitingOnYou.length} to answer in the chat</span>}
          <button type="button" onClick={() => setAllOpen(!allOpen)} className="text-xs font-bold underline">All sessions</button>
        </div>
      </div>
      {allOpen && (
        <div className={`mb-3 p-3 ${PANEL}`}>
          <ul className="flex flex-col gap-1 text-sm">
            {[...upcoming, ...past].map((s) => (
              <li key={s.id} className="flex items-center justify-between gap-2"><span>{when(s).day} · {when(s).range}</span><StateBadge s={s} /></li>
            ))}
            {upcoming.length + past.length === 0 && <li className="text-black/65">None yet.</li>}
          </ul>
        </div>
      )}

      <div className="grid items-start gap-6 lg:grid-cols-[minmax(0,1fr)_300px]">
        <div className="flex flex-col gap-2">
          {/* Links strip: everything shared lives here, and also shows in the chat when added. */}
          {stub.resources.length > 0 && (
            <div className="flex gap-2 overflow-x-auto pb-1">
              {stub.resources.map((r) => (
                <span key={r.id} className="inline-flex shrink-0 items-center gap-1 rounded-full border-2 border-black bg-white px-3 py-1 text-xs font-bold">
                  <a href={r.url} target="_blank" rel="noopener noreferrer" className="underline">{host(r.url)}</a>
                  {!ended && <button type="button" aria-label="Remove link" onClick={() => stub.removeResource(r.id)}><X className="h-3 w-3" /></button>}
                </span>
              ))}
            </div>
          )}
          <ChatPanel partnership={partnership}>
            {stub.resources.slice().reverse().map((r) => <LinkEvent key={`r${r.id}`} r={r} partnerName={name} />)}
            {events.map((s) => <SessionEvent key={s.id} s={s} stub={stub} ended={ended} partnerName={name} />)}
          </ChatPanel>
          {!ended && (
            <div className={`p-3 ${PANEL}`}>
              <div className="flex gap-2">
                <Button size="sm" variant={tool === "session" ? "default" : "neutral"} onClick={() => setTool(tool === "session" ? null : "session")}><CalendarPlus className="h-4 w-4" />Propose a session</Button>
                <Button size="sm" variant={tool === "link" ? "default" : "neutral"} onClick={() => setTool(tool === "link" ? null : "link")}><Link2 className="h-4 w-4" />Share a link</Button>
              </div>
              {tool === "session" && <div className="mt-3"><ProposeForm stub={stub} partnerName={name} columns onDone={() => setTool(null)} /></div>}
              {tool === "link" && <div className="mt-3"><AddLinkForm stub={stub} onDone={() => setTool(null)} /></div>}
            </div>
          )}
        </div>
        <div className="flex flex-col gap-6">
          {slots.checkIns}
          {slots.commitments}
          {slots.end}
        </div>
      </div>
    </>
  );
}

// ---------- Variant C: tabs, with Sessions and Resources as full pages ----------

function VariantC({ partnership, stub, slots }) {
  const name = partnership.conversation.other.name;
  const { upcoming, past, waitingOnYou } = stub.sessions;
  const [tab, setTab] = useState("Chat");
  const ended = partnership.ended;
  const tabs = [
    { key: "Chat" },
    { key: "Sessions", count: waitingOnYou.length },
    { key: "Resources", count: 0, total: stub.resources.length },
  ];

  const group = (title, list) => list.length > 0 && (
    <section className="mb-6">
      <h2 className="mb-2 text-xs font-bold uppercase tracking-widest text-black/65">{title}</h2>
      <ul className="flex flex-col gap-3">
        {list.map((s) => {
          const note = stateNote(s, name);
          return (
            <li key={s.id} className={`flex flex-col gap-3 p-4 md:flex-row md:items-center md:justify-between ${PANEL} ${["declined", "withdrawn", "cancelled", "expired"].includes(s.state) ? "opacity-70 shadow-none" : ""}`}>
              <div className="flex items-start gap-3">
                <StateBadge s={s} />
                <div>
                  <When s={s} partnerName={name} />
                  {note && <p className="text-xs text-black/65">{note}</p>}
                  {s.link && s.state === "confirmed" && <p className="truncate text-xs">{host(s.link)}</p>}
                </div>
              </div>
              <SessionActions s={s} stub={stub} ended={ended} />
            </li>
          );
        })}
      </ul>
    </section>
  );

  return (
    <>
      <div role="tablist" className="mb-4 flex gap-2 overflow-x-auto">
        {tabs.map((t) => (
          <button key={t.key} role="tab" aria-selected={tab === t.key} type="button" onClick={() => setTab(t.key)} className={`flex shrink-0 items-center gap-1.5 rounded-xl border-2 border-black px-4 py-2 text-sm font-bold ${tab === t.key ? "bg-purple text-white" : "bg-white"}`}>
            {t.key}
            {t.count > 0 && <span className="rounded-full bg-orange px-1.5 text-xs text-black">{t.count}</span>}
            {t.total > 0 && <span className="text-xs opacity-70">{t.total}</span>}
          </button>
        ))}
      </div>

      {tab === "Chat" && (
        <div className="grid items-start gap-6 lg:grid-cols-[minmax(0,1fr)_320px]">
          <ChatPanel partnership={partnership} />
          <div className="flex flex-col gap-6">
            {stub.sessions.next && (
              <button type="button" onClick={() => setTab("Sessions")} className={`p-4 text-left ${PANEL} bg-green/20`}>
                <p className="text-xs font-bold uppercase tracking-wide">Next session</p>
                <When s={stub.sessions.next} partnerName={name} compact />
              </button>
            )}
            {slots.checkIns}
            {slots.commitments}
            {slots.end}
          </div>
        </div>
      )}

      {tab === "Sessions" && (
        <div className="grid items-start gap-6 lg:grid-cols-[360px_minmax(0,1fr)]">
          {!ended && (
            <div className={`p-4 lg:sticky lg:top-4 ${PANEL}`}>
              <p className="mb-3 font-bold">Propose a session</p>
              <ProposeForm stub={stub} partnerName={name} />
            </div>
          )}
          <div>
            {upcoming.length + past.length === 0 && <p className="text-black/65">No sessions yet. Propose one and {name} can confirm it.</p>}
            {group("Upcoming", upcoming)}
            {group("Past", past)}
          </div>
        </div>
      )}

      {tab === "Resources" && (
        <div className="grid items-start gap-6 lg:grid-cols-[360px_minmax(0,1fr)]">
          {!ended && (
            <div className={`p-4 ${PANEL}`}>
              <p className="mb-3 font-bold">Add a link</p>
              <AddLinkForm stub={stub} />
            </div>
          )}
          <div>
            {stub.resources.length === 0 && <p className="text-black/65">Nothing shared yet. Docs, repos and exercises you both want to keep go here.</p>}
            <ul className="grid gap-3 sm:grid-cols-2">
              {stub.resources.map((r) => (
                <li key={r.id} className={`p-4 ${PANEL}`}><ul><ResourceLine r={r} stub={stub} ended={ended} partnerName={name} /></ul></li>
              ))}
            </ul>
          </div>
        </div>
      )}
    </>
  );
}

// ---------- switcher host ----------

function Stubbed({ Variant, screen, ...props }) {
  const stub = useWorkspaceStub(screen);
  return <Variant stub={stub} {...props} />;
}

export default function WorkspacePrototype({ partnership, header, goal, slots }) {
  const params = new URLSearchParams(window.location.search);
  const variant = params.get("variant") ?? "A";
  const screen = params.get("screen") ?? "full";
  const shown = { ...partnership, ended: partnership.ended || screen === "ended", conversation: { ...partnership.conversation, can_send: partnership.conversation.can_send && screen !== "ended" } };

  const go = (next) => {
    const p = new URLSearchParams(window.location.search);
    Object.entries(next).forEach(([k, v]) => p.set(k, v));
    router.visit(`${window.location.pathname}?${p}`, { preserveScroll: true, replace: true });
  };

  const Variant = { A: VariantA, B: VariantB, C: VariantC }[variant] ?? VariantA;

  return (
    <div className="mx-auto w-full max-w-6xl px-4 pb-32 pt-2 md:px-8 md:pt-8">
      {header}
      <div className="mb-3 md:mb-6">{goal}</div>
      {/* key: a new screen reseeds the stub data */}
      <Stubbed key={`${variant}-${screen}`} Variant={Variant} screen={screen} partnership={shown} slots={screen === "ended" ? { ...slots, end: null } : slots} />
      <PrototypeSwitcher
        variants={VARIANTS}
        current={variant}
        onChange={(v) => go({ variant: v })}
        screens={SCREENS}
        screen={screen}
        onScreen={(s) => go({ screen: s })}
      />
    </div>
  );
}
