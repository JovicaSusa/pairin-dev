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
// e.g. { day: "Tue, 3 Nov", time: "18:00–19:00" }.
export function slotParts(startAt, endAt, timeZone) {
  const day = new Intl.DateTimeFormat(undefined, { weekday: "short", day: "numeric", month: "short", timeZone });
  const time = new Intl.DateTimeFormat(undefined, { hour: "2-digit", minute: "2-digit", hour12: false, timeZone });

  return {
    day: day.format(new Date(startAt)),
    time: `${time.format(new Date(startAt))}–${time.format(new Date(endAt))}`,
  };
}
