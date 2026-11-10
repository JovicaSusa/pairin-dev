import { Link, router, useForm } from "@inertiajs/react";
import { useState } from "react";
import { CalendarPlus, Check } from "lucide-react";
import SessionTime, { isoDay, isoTime, when, zonedTime, zoneLabel } from "@/components/SessionTime";
import WorkspaceFrame from "@/components/WorkspaceFrame";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

const PANEL = "rounded-2xl border-2 border-black bg-white shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]";
const DAY = 24 * 60 * 60 * 1000;

const BADGE = {
  proposed: ["Proposed", "bg-yellow-50"],
  confirmed: ["Confirmed", "bg-green"],
  done: ["Done", "bg-white"],
  took_place: ["Took place", "bg-green"],
  didnt_happen: ["Didn't happen", "bg-black/5 text-black/65"],
  declined: ["Declined", "bg-black/5 text-black/65"],
  withdrawn: ["Withdrawn", "bg-black/5 text-black/65"],
  cancelled: ["Cancelled", "bg-black/5 text-black/65"],
  expired: ["Expired", "bg-black/5 text-black/65"],
};

function lengthLabel(minutes) {
  if (minutes < 60) return `${minutes} min`;
  const hours = minutes / 60;
  return `${hours} ${hours === 1 ? "hour" : "hours"}`;
}

const CHIP = "rounded-full border-2 border-black px-3 py-1 text-xs font-bold";
const MINUTE = 60 * 1000;

// "Mon 4 Mar 18:00–20:00" for each stretch starting in the next week.
function hoursText(hours, timeZone) {
  const weekAhead = Date.now() + 7 * DAY;
  return hours
    .filter(([from]) => Date.parse(from) < weekAhead)
    .map(([from, to]) => {
      const { day, range } = when(from, to, timeZone);
      return `${day} ${range}`;
    })
    .join(", ");
}

// Times you're both usually free, from your weekly hours, and a note when the
// chosen time is outside the partner's. Only ever a hint: any time can be
// proposed (#261).
function Availability({ availability, data, setData, timezone, name }) {
  const { suggestions, my_hours: mine, partner_hours: theirs, hours_path: hoursPath } = availability;
  const chips = suggestions[data.minutes] ?? [];
  const start = zonedTime(data.date, data.time, timezone);
  const end = start && new Date(start.getTime() + Number(data.minutes) * MINUTE);
  const pick = (at) => {
    const date = new Date(at);
    setData((current) => ({ ...current, date: isoDay(date, timezone), time: isoTime(date, timezone) }));
  };

  // Only as far ahead as the partner's hours were sent.
  const lastKnown = theirs.length > 0 ? Date.parse(theirs[theirs.length - 1][1]) : 0;
  const outside = start && start.getTime() > Date.now() && start.getTime() < lastKnown &&
    !theirs.some(([from, to]) => Date.parse(from) <= start.getTime() && end.getTime() <= Date.parse(to));

  return (
    <div className="flex flex-col gap-2">
      {chips.length > 0 ? (
        <>
          <p className="text-sm font-bold">You're both usually free</p>
          <div className="flex flex-wrap gap-2">
            {chips.map((at) => {
              const date = new Date(at);
              const chosen = start && start.getTime() === date.getTime();
              const { day } = when(at, at, timezone);
              return (
                <button key={at} type="button" aria-pressed={Boolean(chosen)} onClick={() => pick(at)} className={`${CHIP} ${chosen ? "bg-purple text-white" : "bg-white hover:bg-yellow-50"}`}>
                  {day} · {isoTime(date, timezone)}
                </button>
              );
            })}
          </div>
        </>
      ) : (
        <div className="text-xs text-black/65">
          {mine.length > 0 && theirs.length > 0 && <p className="mb-1 font-bold">No shared hours in the next week that fit {lengthLabel(Number(data.minutes))}.</p>}
          {theirs.length > 0 && hoursText(theirs, timezone) && <p>{name} is usually free (your time): {hoursText(theirs, timezone)}</p>}
          {mine.length > 0 && hoursText(mine, timezone) && <p>You're usually free: {hoursText(mine, timezone)}</p>}
          {theirs.length === 0 && <p>{name} hasn't added their usual hours yet.</p>}
        </div>
      )}
      {mine.length === 0 && (
        <p className="text-xs text-black/65">
          <Link href={hoursPath} className="font-bold underline">Add your hours</Link> to see times you're both free.
        </p>
      )}
      {outside && (
        <p role="status" className="rounded-xl border-2 border-black bg-yellow-50 p-2 text-xs font-bold">
          Outside {name}'s usual hours. You can still propose it.
        </p>
      )}
    </div>
  );
}

function ProposeForm({ partnership }) {
  const { timezone, lengths } = partnership;
  const now = new Date();
  const { data, setData, post, processing, errors, reset } = useForm({
    date: isoDay(new Date(now.getTime() + DAY), timezone),
    time: "18:00",
    minutes: "60",
    call_link: "",
  });

  const submit = (e) => {
    e.preventDefault();
    post(`/partners/${partnership.id}/sessions`, { preserveScroll: true, onSuccess: () => reset("call_link") });
  };

  return (
    <form onSubmit={submit} className={`flex flex-col gap-3 p-4 md:p-5 ${PANEL}`}>
      <p className="font-bold">Propose a session</p>
      <div className="grid grid-cols-2 gap-3">
        <div className="col-span-2">
          <Label htmlFor="session_date" className="mb-1 block text-sm">Date</Label>
          <Input id="session_date" type="date" required min={isoDay(now, timezone)} value={data.date} onChange={(e) => setData("date", e.target.value)} />
        </div>
        <div>
          <Label htmlFor="session_time" className="mb-1 block text-sm">Start ({zoneLabel(now, timezone)})</Label>
          <Input id="session_time" type="time" required value={data.time} onChange={(e) => setData("time", e.target.value)} />
        </div>
        <div>
          <Label htmlFor="session_minutes" className="mb-1 block text-sm">Length</Label>
          <select
            id="session_minutes"
            value={data.minutes}
            onChange={(e) => setData("minutes", e.target.value)}
            className="h-10 w-full rounded-base border-2 border-black bg-white px-2 text-sm font-base"
          >
            {lengths.map((minutes) => <option key={minutes} value={minutes}>{lengthLabel(minutes)}</option>)}
          </select>
        </div>
      </div>
      <p className="-mt-1 text-xs text-black/65">Times are in your timezone, {timezone}.</p>
      {partnership.availability && (
        <Availability availability={partnership.availability} data={data} setData={setData} timezone={timezone} name={partnership.conversation.other.name} />
      )}
      {errors.start_at && <p className="text-sm font-bold text-red">{errors.start_at}</p>}
      {errors.end_at && <p className="text-sm font-bold text-red">{errors.end_at}</p>}
      <div>
        <Label htmlFor="session_call_link" className="mb-1 block text-sm">Call link (optional)</Label>
        <Input id="session_call_link" type="url" placeholder="https://meet.google.com/…" value={data.call_link} onChange={(e) => setData("call_link", e.target.value)} />
        {errors.call_link && <p className="mt-1 text-sm font-bold text-red">{errors.call_link}</p>}
      </div>
      {errors.base && <p className="text-sm font-bold text-red">{errors.base}</p>}
      <p className="text-xs text-black/65">{partnership.conversation.other.name} gets an email about it.</p>
      <div>
        <Button type="submit" size="sm" disabled={processing}>Propose session</Button>
      </div>
    </form>
  );
}

function note(session, name, past) {
  if (session.status === "proposed") return session.mine ? `Waiting for ${name} to answer` : `${name} proposed this`;
  if (session.status === "expired") return "Nobody answered before it started";
  if (session.status === "declined") return session.mine ? `${name} declined` : "You declined";
  if (session.status === "withdrawn") return session.mine ? "You withdrew this" : `${name} withdrew this`;
  if (session.status === "cancelled") {
    if (session.cancelled_by === "you") return "You cancelled";
    if (session.cancelled_by === "partner") return `${name} cancelled`;
    return "Cancelled when the partnership ended";
  }
  if (session.status === "confirmed" && !past) return session.mine ? `You proposed it, ${name} confirmed` : `${name} proposed it, you confirmed`;
  // After it ends, both partners are emailed "Did it happen?" (#232).
  if (session.status === "confirmed" && session.ended && session.happened === null) return "Did it happen? We've emailed you both to ask";
  return null;
}

function SessionActions({ session, partnership }) {
  const [confirmingCancel, setConfirmingCancel] = useState(false);
  const [busy, setBusy] = useState(false);
  const { can } = session;
  const act = (action) => router.patch(
    `/partners/${partnership.id}/sessions/${session.id}/${action}`,
    {},
    { preserveScroll: true, onStart: () => setBusy(true), onFinish: () => setBusy(false) },
  );

  if (can.answer) {
    return (
      <div className="flex flex-wrap gap-2">
        <Button size="sm" disabled={busy} onClick={() => act("confirm")}>
          <Check className="h-4 w-4" />
          Confirm
        </Button>
        <Button size="sm" variant="neutral" disabled={busy} onClick={() => act("decline")}>Decline</Button>
      </div>
    );
  }

  if (can.withdraw) {
    return <Button size="sm" variant="neutral" disabled={busy} onClick={() => act("withdraw")}>Withdraw</Button>;
  }

  if (can.cancel) {
    if (!confirmingCancel) {
      return <Button size="sm" variant="neutral" onClick={() => setConfirmingCancel(true)}>Cancel session</Button>;
    }

    return (
      <div className="flex flex-col gap-2 rounded-xl border-2 border-black bg-yellow-50 p-3">
        <p className="text-sm font-bold">Cancel this session? We'll tell {partnership.conversation.other.name}.</p>
        <div className="flex flex-wrap gap-2">
          <Button size="sm" disabled={busy} onClick={() => act("cancel")}>Yes, cancel it</Button>
          <Button size="sm" variant="neutral" onClick={() => setConfirmingCancel(false)}>Keep it</Button>
        </div>
      </div>
    );
  }

  return null;
}

// A confirmed session that has started: whether it took place, once a partner
// has said so. Completed means at least one said yes.
function pastState(session) {
  if (session.happened === true) return "took_place";
  if (session.happened === false) return "didnt_happen";
  return "done";
}

function SessionCard({ session, partnership, past }) {
  const name = partnership.conversation.other.name;
  const state = past && session.status === "confirmed" ? pastState(session) : session.status;
  const [label, style] = BADGE[state];
  const faded = ["declined", "withdrawn", "cancelled", "expired", "didnt_happen"].includes(state);
  const text = note(session, name, past);

  return (
    <li className={`flex min-w-0 items-start gap-3 p-4 ${PANEL} ${faded ? "opacity-70 shadow-none" : ""}`}>
      <span className={`inline-flex shrink-0 items-center rounded-full border-2 border-black px-2 py-0.5 text-xs font-bold ${style}`}>{label}</span>
      <div className="min-w-0 flex-1">
        <SessionTime session={session} timeZone={partnership.timezone} partnerTimeZone={partnership.partner_timezone} partnerName={name} />
        {text && <p className="text-xs text-black/65">{text}</p>}
        {session.call_link && !faded && !past && (
          <a href={session.call_link} target="_blank" rel="noopener noreferrer nofollow" className="mt-1 block truncate text-xs font-bold underline">
            {session.call_link.replace(/^https?:\/\//, "")}
          </a>
        )}
        <div className="mt-3 empty:hidden">
          {/* A plain link: it downloads a file, so no Inertia visit (#230). */}
          {session.calendar_path && (
            <a href={session.calendar_path} download className="mb-3 inline-flex items-center gap-1.5 text-xs font-bold underline">
              <CalendarPlus className="h-3.5 w-3.5" />
              Add to calendar
            </a>
          )}
          <SessionActions session={session} partnership={partnership} />
        </div>
      </div>
    </li>
  );
}

function Group({ title, sessions, partnership, past = false }) {
  if (sessions.length === 0) return null;

  return (
    <section className="mb-6">
      <h2 className="mb-2 text-xs font-bold uppercase tracking-widest text-black/65">{title}</h2>
      <ul className="flex flex-col gap-3">
        {sessions.map((session) => <SessionCard key={session.id} session={session} partnership={partnership} past={past} />)}
      </ul>
    </section>
  );
}

// The Workspace's Sessions page: propose a time, and see every session (#228).
export default function Sessions({ partnership }) {
  const { upcoming, past } = partnership.sessions;
  const name = partnership.conversation.other.name;

  return (
    <WorkspaceFrame partnership={partnership} title="Sessions" back={{ href: `/partners/${partnership.id}`, label: "Overview" }}>
      <div className="grid grid-cols-1 items-start gap-4 md:gap-6 lg:grid-cols-[340px_minmax(0,1fr)]">
        {!partnership.ended && <ProposeForm partnership={partnership} />}
        <div className={`min-w-0 ${partnership.ended ? "lg:col-span-2" : ""}`}>
          {upcoming.length + past.length === 0 && (
            <p className="text-black/65">No sessions yet. Propose a time and {name} can answer it here.</p>
          )}
          <Group title="Upcoming" sessions={upcoming} partnership={partnership} />
          <Group title="Past" sessions={past} partnership={partnership} past />
        </div>
      </div>
    </WorkspaceFrame>
  );
}
