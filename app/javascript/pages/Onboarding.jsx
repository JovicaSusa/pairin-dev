import { Head, router, useForm } from "@inertiajs/react";
import { useMemo, useState } from "react";
import { X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Progress } from "@/components/ui/progress";
import { Textarea } from "@/components/ui/textarea";

const LEVEL_LABELS = {
  novice: "Just starting",
  advanced_beginner: "Know the basics",
  competent: "Building things",
  proficient: "Comfortable",
  expert: "Expert",
};

// Start and end options every 30 minutes; 24:00 only makes sense as an end time.
const TIME_OPTIONS = Array.from({ length: 49 }, (_, i) => i * 30);
const formatMinute = (minute) => `${String(Math.floor(minute / 60)).padStart(2, "0")}:${String(minute % 60).padStart(2, "0")}`;
const SELECT_CLASS = "rounded-base border-2 border-black bg-white p-2 font-base";

const choiceClass = (selected) =>
  `w-full rounded-xl border-2 border-black p-3 text-left font-bold ${selected ? "bg-purple text-white" : "bg-white hover:bg-yellow-50"}`;

// Type to filter existing tags, pick with click or Enter, or add a new one.
function TopicCombobox({ tags, value, onChange }) {
  const [query, setQuery] = useState("");
  const [open, setOpen] = useState(false);
  const [active, setActive] = useState(0);

  const q = query.trim().toLowerCase();
  const chosen = value.map((name) => name.toLowerCase());
  const matches = tags
    .filter((name) => !chosen.includes(name.toLowerCase()) && (!q || name.toLowerCase().includes(q)))
    .slice(0, 8);
  const exists = tags.some((name) => name.toLowerCase() === q) || chosen.includes(q);
  const options = [
    ...matches.map((name) => ({ name, isNew: false })),
    ...(q && !exists ? [{ name: query.trim(), isNew: true }] : []),
  ];

  const pick = (name) => {
    onChange([...value, name]);
    setQuery("");
    setActive(0);
  };

  const onKeyDown = (e) => {
    if (e.key === "ArrowDown") {
      e.preventDefault();
      setOpen(true);
      setActive((a) => Math.min(a + 1, options.length - 1));
    } else if (e.key === "ArrowUp") {
      e.preventDefault();
      setActive((a) => Math.max(a - 1, 0));
    } else if (e.key === "Enter") {
      e.preventDefault();
      if (options[active]) pick(options[active].name);
    } else if (e.key === "Backspace" && !query && value.length) {
      onChange(value.slice(0, -1));
    } else if (e.key === "Escape") {
      setOpen(false);
    }
  };

  return (
    <div className="relative">
      <div className="flex flex-wrap items-center gap-2 rounded-xl border-2 border-black bg-white p-2">
        {value.map((name) => (
          <span key={name} className="flex items-center gap-1 rounded-full border-2 border-black bg-purple px-2 py-0.5 text-sm font-bold text-white">
            {name}
            <button type="button" aria-label={`Remove ${name}`} onClick={() => onChange(value.filter((v) => v !== name))}>
              <X className="h-3.5 w-3.5" />
            </button>
          </span>
        ))}
        <input
          role="combobox"
          aria-label="Topic"
          aria-expanded={open}
          aria-controls="topic-options"
          autoFocus
          className="min-w-[10rem] flex-1 border-0 bg-transparent p-1 outline-none focus:ring-0"
          placeholder={value.length ? "Add another" : "Search: Python, React, SQL"}
          value={query}
          onChange={(e) => {
            setQuery(e.target.value);
            setOpen(true);
            setActive(0);
          }}
          onFocus={() => setOpen(true)}
          onBlur={() => setTimeout(() => setOpen(false), 120)}
          onKeyDown={onKeyDown}
        />
      </div>
      {open && options.length > 0 && (
        <ul id="topic-options" role="listbox" className="absolute z-10 mt-1 w-full overflow-hidden rounded-xl border-2 border-black bg-white shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]">
          {options.map((option, i) => (
            <li
              key={option.name}
              role="option"
              aria-selected={i === active}
              onMouseDown={(e) => {
                e.preventDefault();
                pick(option.name);
              }}
              onMouseEnter={() => setActive(i)}
              className={`cursor-pointer px-3 py-2 text-sm ${i === active ? "bg-yellow-100" : ""}`}
            >
              {option.isNew ? <>Add "<strong>{option.name}</strong>"</> : option.name}
            </li>
          ))}
        </ul>
      )}
      <p className="mt-2 text-sm text-black/65">Can't find it? Type it and add it.</p>
    </div>
  );
}

function WeeklyHours({ weekdays, windows, onChange, timezone, onTimezone }) {
  const [weekday, setWeekday] = useState(weekdays[1]?.value ?? weekdays[0].value);
  const [start, setStart] = useState(18 * 60);
  const [end, setEnd] = useState(20 * 60);
  const dayName = (value) => weekdays.find((d) => d.value === value)?.label;

  const zones = useMemo(() => {
    const all = typeof Intl.supportedValuesOf === "function" ? Intl.supportedValuesOf("timeZone") : [];
    return [...new Set([timezone, "UTC", ...all].filter(Boolean))].sort();
  }, [timezone]);

  const overlaps = windows.some((w) => w.weekday === weekday && w.start_minute < end && start < w.end_minute);
  const canAdd = start < end && !overlaps;

  const add = () => {
    if (canAdd) onChange([...windows, { weekday, start_minute: start, end_minute: end }]);
  };

  return (
    <div>
      <div className="flex flex-wrap items-end gap-2">
        <select aria-label="Day" className={SELECT_CLASS} value={weekday} onChange={(e) => setWeekday(Number(e.target.value))}>
          {weekdays.map((d) => <option key={d.value} value={d.value}>{d.label}</option>)}
        </select>
        <select aria-label="From" className={SELECT_CLASS} value={start} onChange={(e) => setStart(Number(e.target.value))}>
          {TIME_OPTIONS.slice(0, -1).map((m) => <option key={m} value={m}>{formatMinute(m)}</option>)}
        </select>
        <span className="pb-2">to</span>
        <select aria-label="To" className={SELECT_CLASS} value={end} onChange={(e) => setEnd(Number(e.target.value))}>
          {TIME_OPTIONS.slice(1).map((m) => <option key={m} value={m}>{formatMinute(m)}</option>)}
        </select>
        <Button type="button" variant="neutral" disabled={!canAdd} onClick={add}>Add</Button>
      </div>

      {windows.length > 0 && (
        <ul className="mt-3 flex flex-wrap gap-2">
          {windows.map((w, i) => (
            <li key={`${w.weekday}-${w.start_minute}`} className="flex items-center gap-1 rounded-full border-2 border-black bg-white px-3 py-1 text-sm font-bold">
              {dayName(w.weekday)} {formatMinute(w.start_minute)}–{formatMinute(w.end_minute)}
              <button type="button" aria-label="Remove these hours" onClick={() => onChange(windows.filter((_, j) => j !== i))}>
                <X className="h-3.5 w-3.5" />
              </button>
            </li>
          ))}
        </ul>
      )}

      <div className="mt-4">
        <Label htmlFor="onboarding_timezone" className="mb-1 block">Your timezone</Label>
        <select id="onboarding_timezone" className={`${SELECT_CLASS} w-full`} value={timezone} onChange={(e) => onTimezone(e.target.value)}>
          {zones.map((zone) => <option key={zone} value={zone}>{zone}</option>)}
        </select>
      </div>
    </div>
  );
}

// The first steps are about you and are saved on their own, so skipping the
// partner search keeps them; only the name is required (#262).
const PROFILE_STEPS = 3;

export default function Onboarding({ tags, levels, commitments, weekdays, name, level, about, timezone }) {
  const detected = Intl.DateTimeFormat().resolvedOptions().timeZone;
  // The column defaults to UTC, so UTC usually means "never set": use the browser's zone.
  const startingZone = timezone === "UTC" && detected ? detected : timezone;

  const { data, setData, post, processing, errors, setError, clearErrors } = useForm({
    name: name ?? "",
    level: level ?? "",
    about: about ?? "",
    topics: [],
    goal: "",
    commitment: "one_to_three_months",
    timezone: startingZone,
    windows: [],
  });
  const [step, setStep] = useState(0);
  const [saving, setSaving] = useState(false);

  const steps = [
    {
      title: "What should partners call you?",
      ready: data.name.trim().length > 0,
      body: (
        <div>
          <Label htmlFor="onboarding_name" className="mb-1 block">Your name</Label>
          <Input id="onboarding_name" autoFocus maxLength={60} autoComplete="given-name" value={data.name} onChange={(e) => setData("name", e.target.value)} />
          <p className="mt-2 text-sm text-black/65">Your partners see this in chats, sessions and emails.</p>
        </div>
      ),
    },
    {
      title: "Where are you at?",
      skippable: true,
      body: (
        <div className="flex flex-col gap-2">
          {levels.map((value) => (
            <button key={value} type="button" className={choiceClass(data.level === value)} aria-pressed={data.level === value} onClick={() => setData("level", value)}>
              {LEVEL_LABELS[value] ?? value}
            </button>
          ))}
        </div>
      ),
    },
    {
      title: "Anything partners should know about you?",
      skippable: true,
      body: (
        <div>
          <Label htmlFor="onboarding_about" className="mb-1 block">About you</Label>
          <Textarea id="onboarding_about" rows={4} value={data.about} placeholder="Backend dev learning Go, usually free on weekday evenings" onChange={(e) => setData("about", e.target.value)} />
        </div>
      ),
    },
    {
      title: "What do you want to learn or practise?",
      ready: data.topics.length > 0,
      body: <TopicCombobox tags={tags} value={data.topics} onChange={(v) => setData("topics", v)} />,
    },
    {
      title: "What's your goal, in a line?",
      skippable: true,
      body: (
        <div>
          <Label htmlFor="onboarding_goal" className="mb-1 block">Your goal</Label>
          <Input id="onboarding_goal" autoFocus value={data.goal} placeholder="Finish a course and build one real project" onChange={(e) => setData("goal", e.target.value)} />
        </div>
      ),
    },
    {
      title: "How long would you like to commit?",
      skippable: true,
      body: (
        <div className="flex flex-col gap-2">
          {commitments.map(({ value, label }) => (
            <button key={value} type="button" className={choiceClass(data.commitment === value)} aria-pressed={data.commitment === value} onClick={() => setData("commitment", value)}>
              {label}
            </button>
          ))}
        </div>
      ),
    },
    {
      title: "When are you usually free?",
      skippable: true,
      body: <WeeklyHours weekdays={weekdays} windows={data.windows} onChange={(v) => setData("windows", v)} timezone={data.timezone} onTimezone={(v) => setData("timezone", v)} />,
    },
  ];

  const current = steps[step];
  const last = step === steps.length - 1;
  const firstError = Object.values(errors)[0];

  // Leaving the last "about you" step saves that part before the search questions.
  const saveProfile = (profile) => router.patch(
    "/onboarding/profile",
    profile,
    {
      preserveState: true,
      preserveScroll: true,
      onStart: () => setSaving(true),
      onFinish: () => setSaving(false),
      onSuccess: () => {
        clearErrors();
        setStep(PROFILE_STEPS);
      },
      onError: (errs) => {
        setError(errs);
        if (errs.name) setStep(0);
      },
    },
  );

  const advance = ({ skipped = false } = {}) => {
    if (step === PROFILE_STEPS - 1) {
      saveProfile({ name: data.name, level: data.level, about: skipped ? "" : data.about });
    } else if (last) {
      post("/onboarding");
    } else {
      setStep(step + 1);
    }
  };

  return (
    <div className="mx-auto flex min-h-[80vh] w-full max-w-xl flex-col justify-center px-4 pb-16 pt-8">
      <Head title="Find a partner" />

      <div className="mb-6 flex items-center justify-between gap-4">
        <Progress value={((step + 1) / steps.length) * 100} className="flex-1" aria-label={`Step ${step + 1} of ${steps.length}`} />
        {/* Only the partner search can be skipped as a whole. */}
        {step >= PROFILE_STEPS && (
          <button type="button" onClick={() => router.post("/onboarding/skip")} className="inline-flex min-h-11 shrink-0 items-center text-xs font-bold text-black/65 hover:text-black">
            Skip setup
          </button>
        )}
      </div>

      <h1 className="mb-5 text-3xl">{current.title}</h1>
      {current.body}

      {firstError && <div className="mt-4 text-sm font-bold text-red">{firstError}</div>}

      <div className="mt-8 flex items-center justify-between gap-2">
        <Button type="button" variant="neutral" disabled={step === 0} onClick={() => setStep(step - 1)}>Back</Button>
        <div className="flex items-center gap-3">
          {current.skippable && !last && (
            <button type="button" disabled={saving} onClick={() => advance({ skipped: true })} className="inline-flex min-h-11 items-center text-sm font-bold text-black/65 hover:text-black">Skip this</button>
          )}
          <Button type="button" disabled={processing || saving || (!current.skippable && !current.ready)} onClick={() => advance()}>
            {last ? (processing ? "Finding..." : "Find me a partner") : "Next"}
          </Button>
        </div>
      </div>
    </div>
  );
}
