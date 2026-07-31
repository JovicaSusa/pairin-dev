import { useForm, Head } from '@inertiajs/react';
import { X } from "lucide-react";
import PageHeader from "@/components/PageHeader";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { DatePicker } from "@/components/ui/date-picker";
import { TIME_SLOTS } from "@/helpers/time-slots";

const splitStartAt = (startAt) => {
  if (!startAt) return { date: '', time: '' };
  const [date = '', time = ''] = startAt.split('T');
  return { date, time: time.slice(0, 5) };
};

const combineStartAt = (date, time) => (date || time ? `${date}T${time}` : '');

const isValidStartAt = (s) => /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/.test(s);

export default function New({ tags }) {
  const { data, setData, post, processing, errors, transform } = useForm({
    subject: '',
    duration: 45,
    description: '',
    periods_attributes: [{start_at: ''}],
    taggings_attributes: [{ tag_attributes: { name: '' } }]
  })

  const handleSubmit = (e) => {
    e.preventDefault()
    transform((formData) => ({
      ...formData,
      periods_attributes: formData.periods_attributes.map((p) => ({
        ...p,
        start_at: isValidStartAt(p.start_at) ? new Date(p.start_at).toISOString() : '',
      })),
    }));
    post('/users/pair_requests');
  }

  const addPeriod = () => {
    const updatedPeriods = [...data.periods_attributes];

    updatedPeriods.push({ start_at: '' });
    setData('periods_attributes', updatedPeriods);
  };

  const removePeriod = (index) => {
    const updatedPeriods = [...data.periods_attributes];

    updatedPeriods.splice(index, 1);
    setData('periods_attributes', updatedPeriods);
  };

  const updatePeriodPart = (index, part, value) => {
    const updatedPeriods = [...data.periods_attributes];
    const { date, time } = splitStartAt(updatedPeriods[index].start_at);

    updatedPeriods[index].start_at =
      part === 'date' ? combineStartAt(value, time) : combineStartAt(date, value);
    setData('periods_attributes', updatedPeriods);
  };

  const addTag = () => {
    const updatedTaggings = [...data.taggings_attributes];

    updatedTaggings.push({
      tag_attributes: { name: '' }
    });
    setData('taggings_attributes', updatedTaggings);
  };

  const removeTag = (index) => {
    const updatedTaggings = [...data.taggings_attributes];

    updatedTaggings.splice(index, 1);
    setData('taggings_attributes', updatedTaggings);
  };

  const updateTag = (index, name) => {
    const updatedTaggings = [...data.taggings_attributes];

    updatedTaggings[index] = {
      tag_attributes: { name: name }
    };

    setData('taggings_attributes', updatedTaggings);
  };

  return (
    <div className="mx-auto w-full max-w-3xl px-4 pb-16 md:px-8">
      <Head title="Create a Request" />

      <PageHeader
        eyebrow="Pair Requests"
        title="Create a request"
        description="Share what you're working on, when you're free, and what stack you're looking for."
      />

      <form onSubmit={handleSubmit} className="flex flex-col items-stretch">
        <div className="flex flex-col gap-4 md:flex-row">
          <div className="w-full md:w-3/4">
            <Label htmlFor="subject" className="block mb-1">Subject</Label>
            <Input
              id="subject"
              type="text"
              value={data.subject}
              onChange={e => setData('subject', e.target.value)}
            />
            {errors.subject && <div className="text-red font-bold mt-1 text-sm">{errors.subject}</div>}
          </div>

          <div className="w-full md:w-1/4">
            <Label htmlFor="duration" className="block mb-1">Duration (min)</Label>
            <Input
              id="duration"
              type="number"
              value={data.duration}
              onChange={e => setData('duration', e.target.value)}
            />
            {errors.duration && <div className="text-red font-bold mt-1 text-sm">{errors.duration}</div>}
          </div>
        </div>

        <div className="w-full mt-4">
          <Label htmlFor="description" className="block mb-1">Description</Label>
          <Textarea
            id="description"
            value={data.description}
            onChange={e => setData('description', e.target.value)}
            rows="4"
          />
          {errors.description && <div className="text-red font-bold mt-1 text-sm">{errors.description}</div>}
        </div>

        <div className="mt-8 grid grid-cols-1 gap-6 md:grid-cols-2">
          <div>
            <h4 className="mb-3 font-headline text-sm font-bold uppercase tracking-widest text-black/50">Periods</h4>

            <div className="flex flex-col gap-3">
              {data.periods_attributes.map((period, index) => {
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
                    {errors["periods.start_at"] && !isValidStartAt(period.start_at) && (
                      <div className="text-red font-bold mt-1 text-sm">
                        {errors["periods.start_at"]}
                      </div>
                    )}
                  </div>
                );
              })}
            </div>

            <Button type="button" size="sm" variant="neutral" onClick={addPeriod} className="mt-3">
              + Add period
            </Button>
          </div>

          <div>
            <h4 className="mb-3 font-headline text-sm font-bold uppercase tracking-widest text-black/50">Tags</h4>

            <div className="flex flex-col gap-3">
              {data.taggings_attributes.map((tagging, index) => (
                <div key={index} className="rounded-xl border-2 border-black bg-white p-3">
                  <Label className="mb-1 block text-black/50">
                    Tag <span className="text-xs font-normal">(select or type new)</span>
                  </Label>

                  <div className="flex gap-2">
                    <div className="relative flex-1">
                      <Input
                        list={`tags-list-${index}`}
                        value={tagging.tag_attributes.name}
                        onChange={(e) => updateTag(index, e.target.value)}
                        placeholder="Search or create..."
                      />
                      <datalist id={`tags-list-${index}`}>
                        {tags.map((t) => (
                          <option key={t.value} value={t.label} />
                        ))}
                      </datalist>
                    </div>

                    <Button
                      type="button"
                      size="icon"
                      variant="neutral"
                      onClick={() => removeTag(index)}
                      aria-label="Remove tag"
                    >
                      <X className="h-4 w-4" />
                    </Button>
                  </div>
                  {errors[`taggings_attributes.${index}.tag_attributes.name`] && (
                    <div className="text-red text-xs font-bold mt-1">
                      {errors[`taggings_attributes.${index}.tag_attributes.name`]}
                    </div>
                  )}
                </div>
              ))}
            </div>

            <div className="mt-3 flex justify-start">
              <Button type="button" size="sm" variant="neutral" onClick={addTag}>
                + Add tag
              </Button>
            </div>
          </div>
        </div>

        <Button type="submit" size="lg" disabled={processing} className="mt-12 self-center">
          {processing ? 'Creating...' : 'Create Pair request'}
        </Button>
      </form>
    </div>
  );
}
