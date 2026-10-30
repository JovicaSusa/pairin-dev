export function formatShort(datetime) {
  if (!datetime) return "";

  const date = new Date(datetime);

  return new Intl.DateTimeFormat(undefined, {
    day: "2-digit",
    month: "short",
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  }).format(date);
}

export function shiftDate(dateString, days) {
    const d = new Date(dateString);
    
    d.setDate(d.getDate() + days);

    return d
  };

// Day and time of a bookable slot in the given IANA zone (the viewer's own),
// e.g. { day: "Tue, 3 Nov", time: "18:00–19:00" }. When the slot spans a
// daylight-saving change in that zone, each time carries its zone name
// ("01:30 EDT–01:15 EST") so the clock times still make sense.
export function slotParts(startAt, endAt, timeZone) {
  const start = new Date(startAt);
  const end = new Date(endAt);
  const day = new Intl.DateTimeFormat(undefined, { weekday: "short", day: "numeric", month: "short", timeZone });
  const time = new Intl.DateTimeFormat(undefined, { hour: "2-digit", minute: "2-digit", hour12: false, timeZone });
  const zoneName = (date) =>
    new Intl.DateTimeFormat(undefined, { timeZoneName: "short", timeZone })
      .formatToParts(date)
      .find((part) => part.type === "timeZoneName")?.value;

  const crossesChange = zoneName(start) !== zoneName(end);
  const clock = (date) => (crossesChange ? `${time.format(date)} ${zoneName(date)}` : time.format(date));

  return {
    day: day.format(start),
    time: `${clock(start)}–${clock(end)}`,
  };
}
