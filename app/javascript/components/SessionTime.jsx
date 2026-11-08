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
