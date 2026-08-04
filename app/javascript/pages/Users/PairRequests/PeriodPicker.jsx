import { X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { DatePicker } from "@/components/ui/date-picker";
import { TIME_SLOTS } from "@/helpers/time-slots";

export const splitStartAt = (startAt) => {
  if (!startAt) return { date: '', time: '' };
  const [date = '', time = ''] = startAt.split('T');
  return { date, time: time.slice(0, 5) };
};

export const combineStartAt = (date, time) => (date || time ? `${date}T${time}` : '');

export const isValidStartAt = (s) => /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/.test(s);

export default function PeriodPicker({ periods, onChange, error }) {
  const addPeriod = () => {
    onChange([...periods, { start_at: '' }]);
  };

  const removePeriod = (index) => {
    const updated = [...periods];
    updated.splice(index, 1);
    onChange(updated);
  };

  const updatePeriodPart = (index, part, value) => {
    const updated = [...periods];
    const { date, time } = splitStartAt(updated[index].start_at);

    updated[index].start_at =
      part === 'date' ? combineStartAt(value, time) : combineStartAt(date, value);
    onChange(updated);
  };

  return (
    <div>
      <div className="flex flex-col gap-3">
        {periods.map((period, index) => {
          const { date, time } = splitStartAt(period.start_at);

          return (
            <div key={index} className="rounded-xl border-2 border-black bg-white p-3">
              <Label className="mb-1 block text-black/50">Start at</Label>
              <div className="flex flex-col gap-2 md:flex-row">
                <div className="md:flex-1">
                  <DatePicker
                    value={date}
                    onChange={(v) => updatePeriodPart(index, 'date', v)}
                    placeholder="Pick a date"
                    disabled={(d) => d < new Date(new Date().setHours(0, 0, 0, 0))}
                  />
                </div>
                <div className="flex gap-2">
                  <div className="flex-1">
                    <Select value={time} onValueChange={(v) => updatePeriodPart(index, 'time', v)}>
                      <SelectTrigger className="w-full">
                        <SelectValue placeholder="Time" />
                      </SelectTrigger>
                      <SelectContent>
                        {TIME_SLOTS.map((slot) => (
                          <SelectItem key={slot} value={slot}>{slot}</SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                  <Button
                    type="button"
                    size="icon"
                    variant="neutral"
                    onClick={() => removePeriod(index)}
                    aria-label="Remove period"
                  >
                    <X className="h-4 w-4" />
                  </Button>
                </div>
              </div>
              {error && !isValidStartAt(period.start_at) && (
                <div className="text-red font-bold mt-1 text-sm">{error}</div>
              )}
            </div>
          );
        })}
      </div>

      <Button type="button" size="sm" variant="neutral" onClick={addPeriod} className="mt-3">
        + Add period
      </Button>
    </div>
  );
}
