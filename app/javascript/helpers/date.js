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
