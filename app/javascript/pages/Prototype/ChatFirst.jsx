// PROTOTYPE ONLY (branch prototype/chat-first-ui). Throwaway, fake data, nothing saved.
// Question: how should the chat-first flow look and hang together?
// Three variants on /prototype/chat_first, switchable with ?variant= and ?screen=.
import { Head } from "@inertiajs/react";
import { useState } from "react";
import { ArrowLeft, Check, Clock, Flag, Link2, Lock, Plus, Send, ShieldBan, Sparkles, Target, Users, X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import PrototypeSwitcher from "@/components/PrototypeSwitcher";

const VARIANTS = [
  { key: "A", name: "Inbox: everything is a conversation" },
  { key: "B", name: "Hub: my search and a pair dashboard" },
  { key: "C", name: "Journey: one page per person" },
];

const SCREENS = [
  { key: "browse", name: "1 Browse" },
  { key: "apply", name: "2 Apply" },
  { key: "review", name: "3 Reply" },
  { key: "chat", name: "4 Chat" },
  { key: "proposal", name: "5 Proposal" },
  { key: "closed", name: "6 Closed" },
  { key: "workspace", name: "7 Workspace" },
];

const SEARCHES = [
  { id: 1, subject: "Python buddy to finish a course together", name: "Maya", level: "Novice", commitment: "1–3 months", tags: ["Python", "Beginner"], overlap: "You overlap on Tue and Thu evenings", hours: "Tue, Thu 18:00–21:00 · Sat mornings", description: "I'm halfway through an online Python course and keep losing momentum. Looking for someone at a similar level to work through exercises and build a small project with." },
  { id: 2, subject: "Consistent partner for Rails side projects", name: "Tom", level: "Competent", commitment: "Open-ended", tags: ["Ruby", "Rails"], overlap: "You overlap on weekends", hours: "Sat, Sun 10:00–14:00", description: "Junior backend dev who wants to ship portfolio projects. I'd like a regular partner to review each other's code and stay accountable." },
  { id: 3, subject: "Interview prep partner, mock interviews weekly", name: "Priya", level: "Proficient", commitment: "A few weeks", tags: ["JavaScript", "Interviews"], overlap: null, hours: "No hours set", description: "Four years in frontend, preparing for job interviews. Looking for someone to swap mock interviews with once a week." },
];

const APPLICANTS = [
  { id: 1, name: "Sam", level: "Novice", github: "github.com/sam-codes", goal: "Finish the course and build one real project", often: "Twice a week", long: "1–3 months", message: "Hi Maya! I'm on the same course, part 2. Evenings suit me and I'd love someone to stay on track with.", waited: "Applied 5h ago", overlap: "You overlap on Tue and Thu evenings" },
  { id: 2, name: "Lena", level: "Advanced beginner", github: null, goal: "Get comfortable with Python for data work", often: "About once a week", long: "A few weeks", message: "I know some basics and want to practise with a real person rather than alone.", waited: "Applied 1d ago", overlap: "You overlap on Thursdays" },
  { id: 3, name: "Jo", level: "Novice", github: "github.com/jo-learns", goal: "Build a small web scraper", often: "More than twice a week", long: "Open-ended", message: "Complete beginner here but very motivated. I can do most evenings.", waited: "Applied 2d ago, search goes Off in 24h", overlap: null },
];

const OPENING = [
  { from: "them", text: "Hi Maya! I'm on the same course, part 2. Evenings suit me and I'd love someone to stay on track with.", at: "Mon 09:12" },
  { from: "me", text: "Great to meet you, Sam. Where are you stuck at the moment?", at: "Mon 12:40" },
  { from: "them", text: "Functions and scope, mostly. How do you like to work? I was thinking one call a week plus a shared repo.", at: "Mon 12:52" },
  { from: "me", text: "That sounds good. Would Tuesday evening work for a first call?", at: "Mon 13:05" },
];

const RESOURCES = [
  { title: "Shared GitHub repo", note: "Exercises and the project", host: "github.com" },
  { title: "Course, part 2", note: "We're on chapter 4", host: "python.example" },
];

const Panel = ({ className = "", children }) => (
  <div className={`rounded-2xl border-2 border-black shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] ${/\bbg-/.test(className) ? "" : "bg-white"} ${className}`}>{children}</div>
);
const Pill = ({ className = "bg-white", children }) => (
  <span className={`inline-flex items-center gap-1 rounded-full border-2 border-black px-2 py-0.5 text-xs font-bold ${className}`}>{children}</span>
);
const Face = ({ name, size = "h-10 w-10" }) => (
  <span className={`flex ${size} shrink-0 items-center justify-center rounded-full border-2 border-black bg-orange font-bold text-white`}>{name[0]}</span>
);
const Overlap = ({ text }) => (
  <span className="inline-flex items-center gap-1 text-xs font-bold text-black/70"><Clock className="h-3.5 w-3.5" />{text ?? "No hours to compare"}</span>
);
const Answers = ({ a, columns = "sm:grid-cols-2" }) => (
  <dl className={`grid grid-cols-1 gap-3 text-sm ${columns}`}>
    {[["Their goal", a.goal], ["How often", a.often], ["How long", a.long], ["Level", a.level], ["GitHub", a.github ?? "Not added"]].map(([k, v]) => (
      <div key={k}><dt className="text-xs font-bold uppercase tracking-wide text-black/50">{k}</dt><dd className="font-medium">{v}</dd></div>
    ))}
  </dl>
);
const SafetyLinks = () => (
  <span className="flex items-center gap-3 text-xs font-bold text-black/50">
    <button type="button" className="flex items-center gap-1 hover:text-black"><Flag className="h-3.5 w-3.5" />Report</button>
    <button type="button" className="flex items-center gap-1 hover:text-black"><ShieldBan className="h-3.5 w-3.5" />Block</button>
  </span>
);

function useMessages() {
  const [messages, setMessages] = useState(OPENING);
  return [messages, (text) => setMessages((m) => [...m, { from: "me", text, at: "Just now" }])];
}

function Messages({ messages }) {
  return (
    <div className="flex flex-col gap-3">
      {messages.map((m, i) => (
        <div key={i} className={`flex flex-col ${m.from === "me" ? "items-end" : "items-start"}`}>
          <p className={`max-w-[85%] rounded-2xl border-2 border-black px-3 py-2 text-sm ${m.from === "me" ? "bg-purple text-white" : "bg-white"}`}>{m.text}</p>
          <span className="mt-0.5 text-[11px] text-black/40">{m.at}</span>
        </div>
      ))}
    </div>
  );
}

function Composer({ onSend, placeholder = "Write a message" }) {
  const [text, setText] = useState("");
  const send = () => { if (text.trim()) { onSend(text.trim()); setText(""); } };
  return (
    <div className="flex items-end gap-2">
      <Textarea rows={1} value={text} onChange={(e) => setText(e.target.value)} placeholder={placeholder} className="min-h-10 flex-1" />
      <Button onClick={send} aria-label="Send"><Send /></Button>
    </div>
  );
}

function ClosedNotice() {
  return (
    <div className="flex items-start gap-2 rounded-xl border-2 border-black bg-black/5 p-3 text-sm">
      <Lock className="mt-0.5 h-4 w-4 shrink-0" />
      <span><b>Maya's search has found its partner, so this chat has ended.</b> You can still read it. <a className="font-bold text-purple underline" href="#open">See 3 open searches</a></span>
    </div>
  );
}

function ApplyFields({ columns = false }) {
  return (
    <div className={`grid gap-4 ${columns ? "md:grid-cols-2" : ""}`}>
      <div className={columns ? "md:col-span-2" : ""}><Label>What do you want to get out of this?</Label><Textarea className="mt-1" rows={2} defaultValue="Finish the course and build one real project" /></div>
      <div><Label>How often can you pair?</Label><Input className="mt-1" defaultValue="Twice a week" /></div>
      <div><Label>How long can you commit?</Label><Input className="mt-1" defaultValue="1–3 months" /></div>
      <div className={columns ? "md:col-span-2" : ""}><Label>Your message to Maya</Label><Textarea className="mt-1" rows={3} defaultValue="Hi Maya! I'm on the same course, part 2." /><p className="mt-1 text-xs text-black/50">This starts your conversation. You can write more once Maya replies.</p></div>
    </div>
  );
}

function SearchCard({ s, go }) {
  return (
    <Panel className="p-5">
      <div className="flex flex-wrap items-start justify-between gap-2"><h3 className="text-xl">{s.subject}</h3><Pill className="bg-green">Partner · {s.commitment}</Pill></div>
      <p className="mt-2 text-sm text-black/60">{s.description}</p>
      <div className="mt-3 flex flex-wrap gap-2">{s.tags.map((t) => <Pill key={t} className="bg-purple text-white">{t}</Pill>)}</div>
      <div className="mt-4 flex flex-col gap-3 border-t-2 border-black/10 pt-3 sm:flex-row sm:items-center sm:justify-between">
        <div className="flex items-center gap-3"><Face name={s.name} /><div><p className="text-sm font-bold">{s.name} · {s.level}</p><Overlap text={s.overlap} /></div></div>
        <Button onClick={() => go("apply")}>Apply</Button>
      </div>
    </Panel>
  );
}

/* ---------------- A: Inbox. One Conversations page holds everything. ---------------- */
const INBOX = [
  { name: "Sam", line: "Would Tuesday evening work?", tag: "Talking", cls: "bg-green" },
  { name: "Lena", line: "New application · 1d ago", tag: "Reply", cls: "bg-orange text-white" },
  { name: "Jo", line: "New application · goes Off in 24h", tag: "Reply", cls: "bg-orange text-white" },
  { name: "Tom", line: "Waiting for Tom to reply", tag: "Sent", cls: "bg-white" },
];

function InboxShell({ activeName, children }) {
  return (
    <div className="grid h-screen grid-cols-1 md:grid-cols-[280px_1fr]">
      <aside className="hidden overflow-y-auto border-r-2 border-black bg-white md:block">
        <h2 className="border-b-2 border-black p-4 text-xl">Conversations</h2>
        {INBOX.map((c) => (
          <div key={c.name} className={`flex items-center gap-3 border-b-2 border-black/10 p-3 ${c.name === activeName ? "bg-purple/10" : ""}`}>
            <Face name={c.name} />
            <div className="min-w-0 flex-1"><p className="flex items-center justify-between gap-1 text-sm font-bold">{c.name}<Pill className={c.cls}>{c.tag}</Pill></p><p className="truncate text-xs text-black/50">{c.line}</p></div>
          </div>
        ))}
      </aside>
      <section className="flex min-h-0 flex-col pb-24">{children}</section>
    </div>
  );
}

function ThreadHeader({ name, sub, action }) {
  return (
    <header className="flex flex-wrap items-center justify-between gap-2 border-b-2 border-black bg-white p-3">
      <div className="flex items-center gap-3"><Face name={name} /><div><p className="font-bold">{name}</p><p className="text-xs text-black/50">{sub}</p></div></div>
      <div className="flex items-center gap-3"><SafetyLinks />{action}</div>
    </header>
  );
}

function VariantA({ screen, go }) {
  const [messages, send] = useMessages();
  const [proposed, setProposed] = useState(false);
  const [open, setOpen] = useState(false);

  if (screen === "browse") {
    return <div className="mx-auto max-w-3xl px-4 pb-32 pt-8"><h1 className="mb-1 text-3xl">Partner searches</h1><p className="mb-6 text-black/50">Find someone to learn with, talk first, then decide.</p><div className="flex flex-col gap-6">{SEARCHES.map((s) => <SearchCard key={s.id} s={s} go={go} />)}</div></div>;
  }
  if (screen === "apply") {
    return <div className="mx-auto max-w-2xl px-4 pb-32 pt-8"><h1 className="mb-1 text-3xl">Apply to Maya's search</h1><p className="mb-6 text-black/50">{SEARCHES[0].subject}</p><Panel className="p-5"><ApplyFields /><Button className="mt-5 w-full" onClick={() => go("review")}>Send application</Button></Panel></div>;
  }
  if (screen === "review") {
    const a = APPLICANTS[0];
    return (
      <InboxShell activeName="Sam">
        <ThreadHeader name={a.name} sub={`Applied to your search · ${a.waited}`} />
        <div className="flex-1 overflow-y-auto p-4">
          <Panel className="mb-4 p-4"><p className="mb-3 text-xs font-bold uppercase tracking-wide text-purple">Application</p><Answers a={a} /><div className="mt-3"><Overlap text={a.overlap} /></div></Panel>
          <Messages messages={OPENING.slice(0, 1)} />
        </div>
        <div className="border-t-2 border-black bg-white p-3"><Composer placeholder="Reply to start chatting" onSend={() => go("chat")} /><button type="button" className="mt-2 text-xs font-bold text-black/50 hover:text-black">Not a match</button></div>
      </InboxShell>
    );
  }
  if (screen === "closed") {
    return <InboxShell activeName="Sam"><ThreadHeader name="Sam" sub="Chat ended" /><div className="flex-1 overflow-y-auto p-4 opacity-70"><Messages messages={OPENING} /></div><div className="border-t-2 border-black bg-white p-3"><ClosedNotice /></div></InboxShell>;
  }
  if (screen === "workspace") {
    return (
      <div className="grid grid-cols-1 md:h-screen md:grid-cols-[1fr_300px]">
        <section className="flex h-[85vh] min-h-0 flex-col md:h-auto md:pb-24">
          <ThreadHeader name="Sam" sub="Your partner since Tuesday · 1–3 months" />
          <div className="flex-1 overflow-y-auto p-4"><Messages messages={messages} /></div>
          <div className="border-t-2 border-black bg-white p-3"><Composer onSend={send} /></div>
        </section>
        <aside className="flex flex-col gap-5 overflow-y-auto border-t-2 border-black bg-white p-4 pb-28 md:border-l-2 md:border-t-0">
          <div><p className="mb-1 flex items-center gap-1 text-xs font-bold uppercase tracking-wide text-purple"><Target className="h-3.5 w-3.5" />Goal</p><p className="text-sm">Finish the course and build one real project</p><button type="button" className="text-xs font-bold text-black/50">Edit</button></div>
          <div><p className="mb-2 flex items-center gap-1 text-xs font-bold uppercase tracking-wide text-purple"><Link2 className="h-3.5 w-3.5" />Resources</p>{RESOURCES.map((r) => <div key={r.title} className="mb-2 rounded-lg border-2 border-black p-2 text-sm"><p className="font-bold">{r.title}</p><p className="text-xs text-black/50">{r.note}</p></div>)}<Button variant="neutral" size="sm" className="w-full"><Plus />Add a link</Button></div>
          <p className="text-xs text-black/50">Weekly check-in email goes out on Sunday. <button type="button" className="font-bold underline">End partnership</button></p>
        </aside>
      </div>
    );
  }
  const incoming = screen === "proposal";
  return (
    <InboxShell activeName="Sam">
      <ThreadHeader name="Sam" sub="Talking · applied to your Python search" action={!incoming && <Button size="sm" disabled={proposed} onClick={() => setProposed(true)}><Users />{proposed ? "Proposed" : "Become partners"}</Button>} />
      {incoming && <div className="flex flex-wrap items-center justify-between gap-2 border-b-2 border-black bg-green/30 p-3"><b className="text-sm">Sam wants to become partners.</b><span className="flex gap-2"><Button size="sm" onClick={() => go("workspace")}><Check />Accept</Button><Button size="sm" variant="neutral">Not yet</Button></span></div>}
      {proposed && <div className="border-b-2 border-black bg-yellow-100 p-3 text-sm font-bold">You proposed. Waiting for Sam to answer, and you can keep talking.</div>}
      <div className="flex-1 overflow-y-auto p-4">
        <button type="button" onClick={() => setOpen(!open)} className="mb-3 text-xs font-bold text-purple underline">{open ? "Hide" : "Show"} Sam's application</button>
        {open && <Panel className="mb-4 p-4"><Answers a={APPLICANTS[0]} /></Panel>}
        <Messages messages={messages} />
      </div>
      <div className="border-t-2 border-black bg-white p-3"><Composer onSend={send} /><button type="button" className="mt-2 text-xs font-bold text-black/50 hover:text-black">Not a match</button></div>
    </InboxShell>
  );
}

/* ---------------- B: Hub. Searches are managed from a board; partners get a dashboard. ---------------- */
function VariantB({ screen, go }) {
  const [messages, send] = useMessages();
  const [drawer, setDrawer] = useState(screen === "apply");
  const [proposed, setProposed] = useState(false);

  if (screen === "browse" || screen === "apply") {
    return (
      <div className="relative px-4 pb-32 pt-8 md:px-8">
        <h1 className="mb-6 text-3xl">Find a partner</h1>
        <div className="grid gap-6 lg:grid-cols-[220px_1fr]">
          <Panel className="h-fit p-4 text-sm"><p className="mb-3 font-bold">Filter</p>{["Overlaps with my hours", "1–3 months", "Open-ended", "Python", "Beginner friendly"].map((f, i) => <label key={f} className="mb-2 flex items-center gap-2"><input type="checkbox" defaultChecked={i === 0} />{f}</label>)}</Panel>
          <Panel className="divide-y-2 divide-black/10 overflow-hidden">
            {SEARCHES.map((s) => (
              <div key={s.id} className="grid items-center gap-3 p-4 md:grid-cols-[1fr_140px_190px_auto]">
                <div><p className="font-bold">{s.subject}</p><p className="text-xs text-black/50">{s.name} · {s.level} · {s.tags.join(", ")}</p></div>
                <Pill className="w-fit bg-green">{s.commitment}</Pill>
                <Overlap text={s.overlap} />
                <Button size="sm" variant="neutral" onClick={() => setDrawer(true)}>Apply</Button>
              </div>
            ))}
          </Panel>
        </div>
        {drawer && (
          <div className="fixed inset-0 z-40 flex justify-end bg-black/40">
            <div className="h-full w-full max-w-md overflow-y-auto border-l-2 border-black bg-white p-5 pb-32">
              <div className="mb-4 flex items-start justify-between"><div><h2 className="text-2xl">Apply to Maya</h2><p className="text-sm text-black/50">{SEARCHES[0].description}</p></div><button type="button" aria-label="Close" onClick={() => setDrawer(false)}><X /></button></div>
              <ApplyFields />
              <Button className="mt-5 w-full" onClick={() => go("review")}>Send application</Button>
            </div>
          </div>
        )}
      </div>
    );
  }
  if (screen === "review") {
    return (
      <div className="px-4 pb-32 pt-8 md:px-8">
        <p className="text-xs font-bold uppercase tracking-widest text-purple">My search · 1–3 months · On</p>
        <h1 className="mb-1 text-3xl">{SEARCHES[0].subject}</h1>
        <p className="mb-6 text-black/50">3 applications are waiting for a reply. Unanswered ones turn this search Off after 72h.</p>
        <div className="grid gap-5 lg:grid-cols-3">
          {APPLICANTS.map((a) => (
            <Panel key={a.id} className="flex flex-col p-4">
              <div className="mb-3 flex items-center gap-3"><Face name={a.name} /><div><p className="font-bold">{a.name}</p><p className="text-xs text-black/50">{a.waited}</p></div></div>
              <Answers a={a} columns="" />
              <p className="my-3 rounded-xl bg-yellow-50 p-3 text-sm">"{a.message}"</p>
              <Overlap text={a.overlap} />
              <div className="mt-auto pt-3"><Composer placeholder={`Reply to ${a.name}`} onSend={() => go("chat")} /><button type="button" className="mt-2 text-xs font-bold text-black/50 hover:text-black">Not a match</button></div>
            </Panel>
          ))}
        </div>
      </div>
    );
  }
  if (screen === "workspace") {
    return (
      <div className="px-4 pb-32 pt-8 md:px-8">
        <div className="mb-5 flex flex-wrap items-center justify-between gap-2"><div><p className="text-xs font-bold uppercase tracking-widest text-purple">Workspace</p><h1 className="text-3xl">You and Sam</h1></div><SafetyLinks /></div>
        <Panel className="mb-6 flex items-start gap-3 bg-purple p-5 text-white"><Target className="mt-1 h-6 w-6 shrink-0" /><div><p className="text-xs font-bold uppercase tracking-wide text-white/70">Working towards</p><p className="text-xl font-bold">Finish the course and build one real project</p></div></Panel>
        <div className="grid gap-6 lg:grid-cols-[1fr_320px]">
          <Panel className="flex h-[60vh] flex-col p-4"><p className="mb-3 font-bold">Chat</p><div className="flex-1 overflow-y-auto"><Messages messages={messages} /></div><div className="pt-3"><Composer onSend={send} /></div></Panel>
          <div className="flex flex-col gap-6">
            <Panel className="p-4"><p className="mb-2 font-bold">This week</p><p className="text-sm text-black/60">Check-in email goes out Sunday: did you two work together?</p><div className="mt-2 flex gap-1">{["Yes", "Yes", "—", "Yes"].map((v, i) => <span key={i} className={`flex-1 rounded-md border-2 border-black py-1 text-center text-xs font-bold ${v === "Yes" ? "bg-green" : "bg-white"}`}>W{i + 1}</span>)}</div></Panel>
            <Panel className="p-4"><p className="mb-2 font-bold">Resources</p>{RESOURCES.map((r) => <p key={r.title} className="mb-2 text-sm"><b>{r.title}</b><br /><span className="text-xs text-black/50">{r.host} · {r.note}</span></p>)}<Button variant="neutral" size="sm" className="w-full"><Plus />Add a link</Button></Panel>
            <button type="button" className="text-left text-xs font-bold text-black/50 underline">End partnership</button>
          </div>
        </div>
      </div>
    );
  }
  const a = APPLICANTS[0];
  const closed = screen === "closed";
  return (
    <div className="grid min-h-screen grid-cols-1 lg:grid-cols-[1fr_340px]">
      <section className="flex h-[80vh] flex-col lg:h-screen lg:pb-24">
        <header className="flex items-center justify-between border-b-2 border-black bg-white p-3"><span className="flex items-center gap-2 font-bold"><ArrowLeft className="h-4 w-4" />My search · Sam</span><SafetyLinks /></header>
        <div className={`flex-1 overflow-y-auto p-4 ${closed ? "opacity-70" : ""}`}><Messages messages={messages} /></div>
        <div className="border-t-2 border-black bg-white p-3">{closed ? <ClosedNotice /> : <Composer onSend={send} />}</div>
      </section>
      <aside className="border-t-2 border-black bg-white p-4 pb-28 lg:border-l-2 lg:border-t-0">
        <div className="mb-4 flex items-center gap-3"><Face name={a.name} size="h-14 w-14" /><div><p className="text-lg font-bold">{a.name}</p><Overlap text={a.overlap} /></div></div>
        <Answers a={a} columns="" />
        {!closed && (
          <div className="mt-6 rounded-2xl border-2 border-black bg-yellow-100 p-4">
            {screen === "proposal" ? (
              <><p className="mb-3 font-bold">Sam wants to become partners</p><Button className="mb-2 w-full" onClick={() => go("workspace")}><Check />Accept</Button><Button variant="neutral" className="w-full">Not yet</Button></>
            ) : proposed ? (
              <p className="text-sm font-bold">You proposed. Waiting for Sam, and you can keep talking.</p>
            ) : (
              <><p className="mb-1 font-bold">Good fit?</p><p className="mb-3 text-sm text-black/60">Becoming partners closes your search and opens a Workspace.</p><Button className="w-full" onClick={() => setProposed(true)}><Users />Become partners</Button></>
            )}
            <button type="button" className="mt-3 text-xs font-bold text-black/50">Not a match</button>
          </div>
        )}
      </aside>
    </div>
  );
}

/* ---------------- C: Journey. One page per person, and it grows with the relationship. ---------------- */
const STAGES = ["Applied", "Talking", "Partners"];

function Stepper({ stage, ended }) {
  return (
    <ol className="flex items-center gap-2">
      {STAGES.map((s, i) => (
        <li key={s} className="flex flex-1 items-center gap-2 last:flex-none">
          <span className={`flex items-center gap-1 whitespace-nowrap rounded-full border-2 border-black px-3 py-1 text-xs font-bold ${ended ? "bg-black/10" : i < stage ? "bg-green" : i === stage ? "bg-purple text-white" : "bg-white text-black/40"}`}>{i < stage && <Check className="h-3 w-3" />}{s}</span>
          {i < 2 && <span className="h-0.5 flex-1 bg-black/30" />}
        </li>
      ))}
    </ol>
  );
}

function JourneyShell({ stage, ended, children, sub }) {
  return (
    <div className="mx-auto max-w-2xl px-4 pb-32 pt-6">
      <div className="mb-4 flex flex-wrap items-center justify-between gap-2"><div className="flex items-center gap-3"><Face name="Sam" size="h-12 w-12" /><div><h1 className="text-2xl">Sam</h1><p className="text-xs text-black/50">{sub}</p></div></div><SafetyLinks /></div>
      <div className="mb-6"><Stepper stage={stage} ended={ended} /></div>
      {children}
    </div>
  );
}

function ApplyWizard({ go }) {
  const steps = [
    ["What do you want to get out of this?", "Finish the course and build one real project"],
    ["How often can you pair?", "Twice a week"],
    ["How long can you commit?", "1–3 months"],
    ["Say hi to Maya", "Hi Maya! I'm on the same course, part 2."],
  ];
  const [i, setI] = useState(0);
  return (
    <div className="mx-auto flex min-h-[70vh] max-w-xl flex-col justify-center px-4 pb-32 pt-8">
      <p className="mb-2 text-xs font-bold uppercase tracking-widest text-purple">Maya's search · question {i + 1} of {steps.length}</p>
      <h1 className="mb-5 text-3xl">{steps[i][0]}</h1>
      <Textarea key={i} rows={3} defaultValue={steps[i][1]} />
      <div className="mt-5 flex justify-between"><Button variant="neutral" disabled={i === 0} onClick={() => setI(i - 1)}>Back</Button><Button onClick={() => (i < steps.length - 1 ? setI(i + 1) : go("review"))}>{i < steps.length - 1 ? "Next" : "Send application"}</Button></div>
    </div>
  );
}

function VariantC({ screen, go }) {
  const [messages, send] = useMessages();
  const [proposed, setProposed] = useState(false);
  const [tab, setTab] = useState("Chat");
  const a = APPLICANTS[0];

  if (screen === "browse") {
    const [top, ...rest] = SEARCHES;
    return (
      <div className="mx-auto max-w-3xl px-4 pb-32 pt-8">
        <p className="mb-2 flex items-center gap-1 text-xs font-bold uppercase tracking-widest text-purple"><Sparkles className="h-3.5 w-3.5" />Closest to what you're after</p>
        <Panel className="mb-8 bg-purple p-6 text-white">
          <h1 className="text-3xl text-white">{top.subject}</h1>
          <p className="mt-3 text-white/80">{top.description}</p>
          <p className="mt-3 text-sm font-bold">{top.name} · {top.level} · {top.commitment} · {top.overlap}</p>
          <Button variant="neutral" className="mt-5 text-black" onClick={() => go("apply")}>Talk to {top.name}</Button>
        </Panel>
        <p className="mb-3 font-bold">Also looking</p>
        <div className="grid gap-4 sm:grid-cols-2">{rest.map((s) => <Panel key={s.id} className="p-4"><p className="font-bold">{s.subject}</p><p className="my-2 text-xs text-black/50">{s.name} · {s.commitment}</p><Overlap text={s.overlap} /><Button size="sm" variant="neutral" className="mt-3 w-full" onClick={() => go("apply")}>Talk to {s.name}</Button></Panel>)}</div>
      </div>
    );
  }
  if (screen === "apply") return <ApplyWizard go={go} />;
  if (screen === "review") {
    return (
      <JourneyShell stage={0} sub="Wants to partner on your Python search · applied 5h ago">
        <Panel className="p-6"><p className="mb-4 text-lg">"{a.message}"</p><Answers a={a} /><div className="mt-4"><Overlap text={a.overlap} /></div></Panel>
        <div className="mt-5"><Composer placeholder="Reply to Sam to start talking" onSend={() => go("chat")} /><button type="button" className="mt-2 text-xs font-bold text-black/50">Not a match</button></div>
      </JourneyShell>
    );
  }
  if (screen === "closed") {
    return <JourneyShell stage={1} ended sub="Chat ended"><div className="opacity-70"><Messages messages={OPENING} /></div><div className="mt-5"><ClosedNotice /></div></JourneyShell>;
  }
  if (screen === "workspace") {
    return (
      <JourneyShell stage={2} sub="Your partner · Workspace">
        <div className="mb-5 flex gap-2">{["Chat", "Goal", "Resources"].map((t) => <button key={t} type="button" onClick={() => setTab(t)} className={`rounded-xl border-2 border-black px-4 py-2 text-sm font-bold ${tab === t ? "bg-purple text-white" : "bg-white"}`}>{t}</button>)}</div>
        {tab === "Chat" && <><Messages messages={messages} /><div className="mt-4"><Composer onSend={send} /></div></>}
        {tab === "Goal" && <Panel className="p-5"><Label>What you're working towards (optional)</Label><Textarea className="mt-1" defaultValue="Finish the course and build one real project" /><p className="mt-4 text-sm text-black/50">Check-in email goes out on Sunday.</p><button type="button" className="mt-2 text-xs font-bold text-black/50 underline">End partnership</button></Panel>}
        {tab === "Resources" && <div className="flex flex-col gap-3">{RESOURCES.map((r) => <Panel key={r.title} className="p-4"><p className="font-bold">{r.title}</p><p className="text-xs text-black/50">{r.host} · {r.note}</p></Panel>)}<Button variant="neutral"><Plus />Add a link</Button></div>}
      </JourneyShell>
    );
  }
  const incoming = screen === "proposal";
  return (
    <JourneyShell stage={1} sub="Applied to your Python search · You overlap on Tue and Thu evenings">
      <Messages messages={messages} />
      <div className="mt-5">
        {incoming ? (
          <Panel className="bg-green/30 p-5 text-center"><Users className="mx-auto mb-2 h-7 w-7" /><p className="mb-1 text-lg font-bold">Sam wants to become partners</p><p className="mb-4 text-sm text-black/60">Accepting opens your Workspace and closes the search.</p><div className="flex justify-center gap-2"><Button onClick={() => go("workspace")}><Check />Accept</Button><Button variant="neutral">Not yet</Button></div></Panel>
        ) : proposed ? (
          <Panel className="bg-yellow-100 p-4 text-center text-sm font-bold">You asked Sam to become partners. Waiting for an answer.</Panel>
        ) : null}
      </div>
      <div className="mt-4"><Composer onSend={send} /></div>
      {!incoming && !proposed && <button type="button" onClick={() => setProposed(true)} className="mt-4 w-full rounded-xl border-2 border-dashed border-black p-3 text-sm font-bold hover:bg-white">Ready to commit? Ask Sam to become partners</button>}
      <button type="button" className="mt-3 text-xs font-bold text-black/50 hover:text-black">Not a match</button>
    </JourneyShell>
  );
}

export default function ChatFirst() {
  const params = new URLSearchParams(window.location.search);
  const [variant, setVariant] = useState(params.get("variant") ?? "A");
  const [screen, setScreen] = useState(params.get("screen") ?? "browse");

  const sync = (v, s) => {
    setVariant(v);
    setScreen(s);
    window.history.replaceState({}, "", `?variant=${v}&screen=${s}`);
    window.scrollTo(0, 0);
  };
  const go = (s) => sync(variant, s);
  const Current = { A: VariantA, B: VariantB, C: VariantC }[variant];

  return (
    <>
      <Head title="Prototype: chat-first UI" />
      <Current key={`${variant}-${screen}`} screen={screen} go={go} />
      <PrototypeSwitcher variants={VARIANTS} current={variant} onChange={(v) => sync(v, screen)} screens={SCREENS} screen={screen} onScreen={go} />
    </>
  );
}
