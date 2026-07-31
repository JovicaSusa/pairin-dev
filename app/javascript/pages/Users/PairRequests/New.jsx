import { useForm, Head } from '@inertiajs/react';
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
    <div className="flex flex-col items-center w-full px-4">
      <Head title="Create a Request" />
      <div className="w-full md:w-3/4 xl:w-4/6 2xl:w-1/2">
        <div className="flex w-full items-center mt-8 pb-8 border-b-4 border-black border-dashed text-center">
          <h3 className="text-5xl font-bold">Create a request</h3>
        </div>

        <form onSubmit={handleSubmit} className="flex flex-col items-center pb-12 mt-12">
          <div className="flex w-full gap-x-4">
            <div className="w-3/4">
              <Label className="block mb-1">Subject</Label>
              <Input
                type="text"
                value={data.subject}
                onChange={e => setData('subject', e.target.value)}
              />
              {errors.subject && <div className="text-red-600 font-bold mt-1">{errors.subject}</div>}
            </div>

            <div className="w-1/4">
              <Label className="block mb-1">Duration (min)</Label>
              <Input
                type="number"
                value={data.duration}
                onChange={e => setData('duration', e.target.value)}
              />
              {errors.duration && <div className="text-red-600 font-bold mt-1">{errors.duration}</div>}
            </div>
          </div>

          <div className="w-full mt-4">
            <Label className="block mb-1">Description</Label>
            <Textarea
              value={data.description}
              onChange={e => setData('description', e.target.value)}
              rows="4"
            />
            {errors.description && <div className="text-red-600 font-bold mt-1">{errors.description}</div>}
          </div>

          <div className="flex flex-col gap-y-8 mt-8 items-start w-full md:flex-row md:gap-x-4 md:gap-y-0">
            <div className="w-full md:w-1/2">
              <h4 className="font-bold mb-4 underline">Periods</h4>
              
              {data.periods_attributes.map((period, index) => {
                const { date, time } = splitStartAt(period.start_at);

                return (
                  <div key={index} className="mb-4 p-2 border-2 border-black rounded-md bg-white">
                    <Label className="block mb-1 text-gray-700">Start at</Label>
                    <div className="flex flex-col gap-2 md:flex-row md:gap-x-2">
                      <div className="md:w-7/12">
                        <DatePicker
                          value={date}
                          onChange={(v) => updatePeriodPart(index, 'date', v)}
                          placeholder="Pick a date"
                          disabled={(d) => d < new Date(new Date().setHours(0, 0, 0, 0))}
                        />
                      </div>
                      <div className="flex gap-x-2 md:w-5/12">
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
                          size="sm"
                          variant="neutral"
                          onClick={() => removePeriod(index)}
                          className="text-red-500"
                        >
                          X
                        </Button>
                      </div>
                    </div>
                    {errors["periods.start_at"] && !isValidStartAt(period.start_at) && (
                      <div className="text-red-600 font-bold mt-1">
                        {errors["periods.start_at"]}
                      </div>
                    )}
                  </div>
                );
              })}

              <Button type="button" size="sm" variant="neutral" onClick={addPeriod} className="mt-2">
                + Add period
              </Button>
            </div>

            <div className="w-full md:w-1/2">
              <h4 className="font-bold mb-4 underline">Tags</h4>
              
              {data.taggings_attributes.map((tagging, index) => (
                <div key={index} className="mb-4 p-2 border-2 border-black rounded-md bg-white">
                  <Label className="block mb-1 text-gray-700">
                    Tag <span className="text-xs font-normal">(select or type new)</span>
                  </Label>

                  <div className="flex gap-x-2">
                    <div className="w-10/12 relative">
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
                      size="sm"
                      variant="neutral"
                      onClick={() => removeTag(index)}
                      className="w-2/12 text-red-500"
                    >
                      X
                    </Button>
                  </div>
                  {errors[`taggings_attributes.${index}.tag_attributes.name`] && (
                    <div className="text-red-600 text-xs font-bold mt-1">
                      {errors[`taggings_attributes.${index}.tag_attributes.name`]}
                    </div>
                  )}
                </div>
              ))}

              <div className="flex justify-start md:justify-end mt-2">
                <Button type="button" size="sm" variant="neutral" onClick={addTag}>
                  + Add tag
                </Button>
              </div>
            </div>
          </div>
          
          <Button type="submit" size="lg" disabled={processing} className="mt-12">
            {processing ? 'Creating...' : 'Create Pair request'}
          </Button>
        </form>
      </div>
    </div>
  );
}

