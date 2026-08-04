import { useForm, Head } from '@inertiajs/react';
import { X } from "lucide-react";
import PageHeader from "@/components/PageHeader";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import TagCombobox from "./TagCombobox";
import PeriodPicker, { isValidStartAt } from "./PeriodPicker";

const humanize = (value) => value.split('_').map((w) => w.charAt(0).toUpperCase() + w.slice(1)).join(' ');

export default function New({ tags, waitMinutesOptions, platformOptions }) {
  const { data, setData, post, processing, errors, transform } = useForm({
    subject: '',
    duration: 45,
    description: '',
    mode: 'scheduled',
    wait_minutes: '',
    requires_approval: false,
    goal: '',
    platform: '',
    pairing_tool: '',
    plan: '',
    periods_attributes: [{start_at: ''}],
    taggings_attributes: [{ tag_attributes: { name: '' } }]
  })

  const handleSubmit = (e) => {
    e.preventDefault()
    transform((formData) => (
      formData.mode === 'scheduled'
        ? {
            ...formData,
            wait_minutes: '',
            requires_approval: false,
            goal: '',
            platform: '',
            pairing_tool: '',
            plan: '',
            periods_attributes: formData.periods_attributes.map((p) => ({
              ...p,
              start_at: isValidStartAt(p.start_at) ? new Date(p.start_at).toISOString() : '',
            })),
          }
        : { ...formData, periods_attributes: [] }
    ));
    post('/users/pair_requests');
  }

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
          <div className="pair_request_subject w-full md:w-3/4">
            <Label htmlFor="subject" className="block mb-1">Subject</Label>
            <Input
              id="subject"
              type="text"
              value={data.subject}
              onChange={e => setData('subject', e.target.value)}
            />
            {errors.subject && <div className="text-red font-bold mt-1 text-sm">{errors.subject}</div>}
          </div>

          <div className="pair_request_duration w-full md:w-1/4">
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

        <div className="pair_request_description w-full mt-4">
          <Label htmlFor="description" className="block mb-1">Description</Label>
          <Textarea
            id="description"
            value={data.description}
            onChange={e => setData('description', e.target.value)}
            rows="4"
          />
          {errors.description && <div className="text-red font-bold mt-1 text-sm">{errors.description}</div>}
        </div>

        <div className="w-full mt-4">
          <Label className="block mb-1">Mode</Label>
          <div className="flex gap-2" role="radiogroup" aria-label="Mode">
            <Button
              type="button"
              role="radio"
              aria-checked={data.mode === 'scheduled'}
              variant={data.mode === 'scheduled' ? 'default' : 'neutral'}
              onClick={() => setData('mode', 'scheduled')}
            >
              Scheduled
            </Button>
            <Button
              type="button"
              role="radio"
              aria-checked={data.mode === 'immediate'}
              variant={data.mode === 'immediate' ? 'default' : 'neutral'}
              onClick={() => setData('mode', 'immediate')}
            >
              Immediate
            </Button>
          </div>
          {errors.mode && <div className="text-red font-bold mt-1 text-sm">{errors.mode}</div>}
        </div>

        {data.mode === 'immediate' && (
          <div className="w-full mt-6 flex flex-col gap-4 rounded-xl border-2 border-black bg-white p-4">
            <div className="flex flex-col gap-4 md:flex-row">
              <div className="w-full md:w-1/2">
                <Label className="block mb-1">Wait time</Label>
                <Select value={String(data.wait_minutes)} onValueChange={(v) => setData('wait_minutes', Number(v))}>
                  <SelectTrigger className="w-full">
                    <SelectValue placeholder="Wait time" />
                  </SelectTrigger>
                  <SelectContent>
                    {waitMinutesOptions.map((minutes) => (
                      <SelectItem key={minutes} value={String(minutes)}>{minutes} minutes</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                {errors.wait_minutes && <div className="text-red font-bold mt-1 text-sm">{errors.wait_minutes}</div>}
              </div>

              <div className="w-full md:w-1/2">
                <Label className="block mb-1">Requires approval</Label>
                <div className="flex gap-2" role="radiogroup" aria-label="Requires approval">
                  <Button
                    type="button"
                    role="radio"
                    aria-checked={!data.requires_approval}
                    variant={!data.requires_approval ? 'default' : 'neutral'}
                    onClick={() => setData('requires_approval', false)}
                  >
                    No
                  </Button>
                  <Button
                    type="button"
                    role="radio"
                    aria-checked={data.requires_approval}
                    variant={data.requires_approval ? 'default' : 'neutral'}
                    onClick={() => setData('requires_approval', true)}
                  >
                    Yes
                  </Button>
                </div>
              </div>
            </div>

            <div className="w-full">
              <Label htmlFor="goal" className="block mb-1">Goal</Label>
              <Textarea
                id="goal"
                value={data.goal}
                onChange={e => setData('goal', e.target.value)}
                rows="3"
              />
              {errors.goal && <div className="text-red font-bold mt-1 text-sm">{errors.goal}</div>}
            </div>

            <div className="flex flex-col gap-4 md:flex-row">
              <div className="w-full md:w-1/2">
                <Label className="block mb-1">Platform</Label>
                <Select value={data.platform} onValueChange={(v) => setData('platform', v)}>
                  <SelectTrigger className="w-full">
                    <SelectValue placeholder="Platform" />
                  </SelectTrigger>
                  <SelectContent>
                    {platformOptions.map((platform) => (
                      <SelectItem key={platform} value={platform}>{humanize(platform)}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                {errors.platform && <div className="text-red font-bold mt-1 text-sm">{errors.platform}</div>}
              </div>

              <div className="w-full md:w-1/2">
                <Label htmlFor="pairing_tool" className="block mb-1">Pairing tool <span className="text-xs font-normal">(optional)</span></Label>
                <Input
                  id="pairing_tool"
                  type="text"
                  value={data.pairing_tool}
                  onChange={e => setData('pairing_tool', e.target.value)}
                />
                {errors.pairing_tool && <div className="text-red font-bold mt-1 text-sm">{errors.pairing_tool}</div>}
              </div>
            </div>

            <div className="w-full">
              <Label htmlFor="plan" className="block mb-1">Plan <span className="text-xs font-normal">(optional)</span></Label>
              <Textarea
                id="plan"
                value={data.plan}
                onChange={e => setData('plan', e.target.value)}
                rows="3"
              />
              {errors.plan && <div className="text-red font-bold mt-1 text-sm">{errors.plan}</div>}
            </div>
          </div>
        )}

        <div className={`mt-8 grid grid-cols-1 gap-6 ${data.mode === 'scheduled' ? 'md:grid-cols-2' : ''}`}>
          {data.mode === 'scheduled' && (
          <div>
            <h4 className="mb-3 font-headline text-sm font-bold uppercase tracking-widest text-black/50">Periods</h4>

            <PeriodPicker
              periods={data.periods_attributes}
              onChange={(periods) => setData('periods_attributes', periods)}
              error={errors["periods.start_at"]}
            />
          </div>
          )}

          <div>
            <h4 className="mb-3 font-headline text-sm font-bold uppercase tracking-widest text-black/50">Tags</h4>

            <div className="flex flex-col gap-3">
              {data.taggings_attributes.map((tagging, index) => (
                <div key={index} className="rounded-xl border-2 border-black bg-white p-3">
                  <Label className="mb-1 block text-black/50">
                    Tag <span className="text-xs font-normal">(select or type new)</span>
                  </Label>

                  <div className="flex gap-2">
                    <div className="flex-1">
                      <TagCombobox
                        tags={tags}
                        value={tagging.tag_attributes.name}
                        onChange={(name) => updateTag(index, name)}
                      />
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
