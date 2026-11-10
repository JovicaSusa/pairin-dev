// Session times arrive in UTC and are shown in a named timezone: the viewer's
// own, and their partner's when it's different.

function parts(date, timeZone, options) {
  return new Intl.DateTimeFormat("en-GB", { timeZone, ...options }).format(date);
}

export function zoneLabel(date, timeZone) {
  return new Intl.DateTimeFormat("en-GB", { timeZone, timeZoneName: "short" })
    .formatToParts(date)
    .find((part) => part.type === "timeZoneName")?.value;
}

// "2030-03-04", the day in that timezone, for date inputs.
export function isoDay(date, timeZone) {
  return new Intl.DateTimeFormat("en-CA", { timeZone, year: "numeric", month: "2-digit", day: "2-digit" }).format(date);
}

// "18:30", the time in that timezone, for time inputs.
export function isoTime(date, timeZone) {
  return new Intl.DateTimeFormat("en-GB", { timeZone, hour: "2-digit", minute: "2-digit", hourCycle: "h23" }).format(date);
}

// How far that timezone's wall clock is ahead of UTC at an instant, in ms.
function offset(instant, timeZone) {
  const p = Object.fromEntries(
    new Intl.DateTimeFormat("en-US", { timeZone, hourCycle: "h23", year: "numeric", month: "numeric", day: "numeric", hour: "numeric", minute: "numeric", second: "numeric" })
      .formatToParts(instant)
      .map(({ type, value }) => [type, Number(value)]),
  );
  return Date.UTC(p.year, p.month - 1, p.day, p.hour, p.minute, p.second) - (instant - (instant % 1000));
}

// The instant of a date ("2030-03-04") and time ("18:30") in a timezone, or
// null if either is missing or doesn't parse (an input mid-edit is empty).
//
// Matches Rails' `Time.find_zone!(tz).local`, which picks the instant the
// session is saved at: a time that happens twice when clocks go back is the
// first (daylight-saving) one, and a time skipped when clocks go forward moves
// on by the jump (02:30 becomes 03:30).
export function zonedTime(day, time, timeZone) {
  const [y, m, d] = (day || "").split("-").map(Number);
  const [h, min] = (time || "").split(":").map(Number);
  if (![y, m, d, h, min].every(Number.isInteger)) return null;

  const wall = Date.UTC(y, m - 1, d, h, min);
  const DAY = 24 * 60 * 60 * 1000;
  // The offsets either side of any change; clocks never change twice in two days.
  const before = wall - offset(wall - DAY, timeZone);
  const after = wall - offset(wall + DAY, timeZone);
  const fits = (instant) => instant + offset(instant, timeZone) === wall;

  if (fits(before) && fits(after)) return new Date(Math.min(before, after));
  if (fits(after)) return new Date(after);
  return new Date(before);
}

export function when(startAt, endAt, timeZone) {
  const start = new Date(startAt);
  const end = new Date(endAt);
  const time = (date) => parts(date, timeZone, { hour: "2-digit", minute: "2-digit", hour12: false });

  return {
    day: parts(start, timeZone, { weekday: "short", day: "numeric", month: "short" }),
    range: `${time(start)}–${time(end)}`,
    zone: zoneLabel(start, timeZone),
  };
}

export default function SessionTime({ session, timeZone, partnerTimeZone, partnerName, className = "" }) {
  const mine = when(session.start_at, session.end_at, timeZone);
  const theirs = partnerTimeZone && partnerTimeZone !== timeZone ? when(session.start_at, session.end_at, partnerTimeZone) : null;

  return (
    <div className={`min-w-0 ${className}`}>
      <p className="font-bold">
        {mine.day} · {mine.range} <span className="text-xs font-bold text-black/65">{mine.zone}</span>
      </p>
      {theirs && (
        <p className="text-xs text-black/65">
          {theirs.day === mine.day ? "" : `${theirs.day}, `}{theirs.range} {theirs.zone} for {partnerName}
        </p>
      )}
    </div>
  );
}
