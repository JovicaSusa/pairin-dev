import { Head, router, usePage } from "@inertiajs/react";
import { useMemo, useState } from "react";
import { Clock, X } from "lucide-react";
import PageHeader from "@/components/PageHeader";
import EmptyState from "@/components/EmptyState";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";

// Start/end options every 30 minutes; 24:00 only makes sense as an end time.
const TIME_OPTIONS = Array.from({ length: 49 }, (_, i) => i * 30);

const formatMinute = (minute) =>
  `${String(Math.floor(minute / 60)).padStart(2, "0")}:${String(minute % 60).padStart(2, "0")}`;

const browserTimezone = () => Intl.DateTimeFormat().resolvedOptions().timeZone;

const SELECT_CLASS = "w-full rounded-base border-2 border-black bg-white p-2 font-base";

export default function Availability({ timezone, windows, weekdays }) {
  const { errors } = usePage().props;

  // The column defaults to UTC, so UTC usually means "never set": suggest the browser's zone.
  const detected = browserTimezone();
  const suggestDetected = timezone === "UTC" && detected && detected !== "UTC";
  const [zone, setZone] = useState(suggestDetected ? detected : timezone);

  const zones = useMemo(() => {
    const all = typeof Intl.supportedValuesOf === "function" ? Intl.supportedValuesOf("timeZone") : [];
    return [...new Set([timezone, detected, "UTC", ...all].filter(Boolean))].sort();
  }, [timezone, detected]);

  const [weekday, setWeekday] = useState(weekdays[0].value);
  const [startMinute, setStartMinute] = useState(18 * 60);
  const [endMinute, setEndMinute] = useState(20 * 60);
  const [adding, setAdding] = useState(false);

  const dayName = (number) => weekdays.find((d) => d.value === number)?.label;
  const describe = (w) => `${dayName(w.weekday)} ${formatMinute(w.start_minute)}–${formatMinute(w.end_minute)}`;

  const saveTimezone = (e) => {
    e.preventDefault();
    router.patch("/availability", { timezone: zone }, { preserveScroll: true });
  };

  const addWindow = (e) => {
    e.preventDefault();
    if (adding) return;
    router.post("/availability/windows", { weekday, start_minute: startMinute, end_minute: endMinute }, {
      preserveScroll: true,
      onStart: () => setAdding(true),
      onFinish: () => setAdding(false),
    });
  };

  const removeWindow = (id) => {
    router.delete(`/availability/windows/${id}`, { preserveScroll: true });
  };

  return (
    <div className="mx-auto w-full max-w-2xl px-4 pb-16 md:px-8">
      <Head title="Availability" />

      <PageHeader
        eyebrow="Availability"
        title="When are you free?"
        description="Your weekly hours, in your own timezone. Others book sessions inside these windows."
      />

      <form onSubmit={saveTimezone} className="mb-10 rounded-2xl border-2 border-black bg-white p-5 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]">
        <Label htmlFor="timezone" className="mb-1 block">Timezone</Label>
        <div className="flex flex-col gap-2 md:flex-row">
          <select id="timezone" className={SELECT_CLASS} value={zone} onChange={(e) => setZone(e.target.value)}>
            {zones.map((z) => <option key={z} value={z}>{z}</option>)}
          </select>
          <Button type="submit" className="md:w-40">Save timezone</Button>
        </div>
        {suggestDetected && zone === detected && (
          <p className="mt-2 text-sm text-black/60">Detected from your browser. Save it if it's right.</p>
        )}
        {errors?.timezone && <p className="mt-2 text-sm font-bold text-red">{errors.timezone}</p>}
      </form>

      <h2 className="mb-3 text-xl">Weekly hours</h2>

      {windows.length > 0 ? (
        <ul className="mb-6 flex flex-col gap-2">
          {windows.map((w) => (
            <li key={w.id} className="flex items-center justify-between rounded-xl border-2 border-black bg-white px-4 py-2">
              <span>{describe(w)}</span>
              <Button type="button" variant="neutral" size="icon" aria-label={`Remove ${describe(w)}`} onClick={() => removeWindow(w.id)}>
                <X className="h-4 w-4" />
              </Button>
            </li>
          ))}
        </ul>
      ) : (
        <EmptyState icon={Clock} title="No weekly hours yet" description="Add the times you're usually free, for example Saturday mornings." />
      )}

      <form onSubmit={addWindow} className="grid grid-cols-1 gap-3 rounded-2xl border-2 border-black bg-white p-5 md:grid-cols-4 md:items-end">
        <div>
          <Label htmlFor="weekday" className="mb-1 block">Day</Label>
          <select id="weekday" className={SELECT_CLASS} value={weekday} onChange={(e) => setWeekday(Number(e.target.value))}>
            {weekdays.map((d) => <option key={d.value} value={d.value}>{d.label}</option>)}
          </select>
        </div>
        <div>
          <Label htmlFor="start_minute" className="mb-1 block">From</Label>
          <select id="start_minute" className={SELECT_CLASS} value={startMinute} onChange={(e) => setStartMinute(Number(e.target.value))}>
            {TIME_OPTIONS.slice(0, -1).map((m) => <option key={m} value={m}>{formatMinute(m)}</option>)}
          </select>
        </div>
        <div>
          <Label htmlFor="end_minute" className="mb-1 block">To</Label>
          <select id="end_minute" className={SELECT_CLASS} value={endMinute} onChange={(e) => setEndMinute(Number(e.target.value))}>
            {TIME_OPTIONS.slice(1).map((m) => <option key={m} value={m}>{formatMinute(m)}</option>)}
          </select>
        </div>
        <Button type="submit" disabled={adding}>Add hours</Button>
        {(errors?.start_minute || errors?.end_minute) && (
          <p className="text-sm font-bold text-red md:col-span-4">{errors.start_minute || errors.end_minute}</p>
        )}
      </form>
    </div>
  );
}
