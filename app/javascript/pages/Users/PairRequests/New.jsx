import { useForm, Head } from '@inertiajs/react';
import { Button } from "@/components/ui/button";

export default function New({ tags }) {
  const { data, setData, post, processing, errors} = useForm({
    subject: '',
    duration: 45,
    description: '',
    periods_attributes: [{start_at: ''}],
    taggings_attributes: [{ tag_attributes: { name: '' } }]
  })

  const handleSubmit = (e) => {
    e.preventDefault()
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

  const updatePeriod = (index, value) => {
    const updatedPeriods = [...data.periods_attributes];

    updatedPeriods[index].start_at = value;
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
              <label className="block font-bold mb-1">Subject</label>
              <input
                type="text"
                value={data.subject}
                onChange={e => setData('subject', e.target.value)}
                className="w-full rounded-md border-2 border-black p-[10px] font-bold shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] outline-none transition-all focus:translate-x-[3px] focus:translate-y-[3px] focus:shadow-none"
              />
              {errors.subject && <div className="text-orange font-bold mt-1">{errors.subject}</div>}
            </div>

            <div className="w-1/4">
              <label className="block font-bold mb-1">Duration (min)</label>
              <input
                type="number"
                value={data.duration}
                onChange={e => setData('duration', e.target.value)}
                className="w-full rounded-md border-2 border-black p-[10px] font-bold shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] outline-none transition-all focus:translate-x-[3px] focus:translate-y-[3px] focus:shadow-none"
              />
              {errors.duration && <div className="text-orange font-bold mt-1">{errors.duration}</div>}
            </div>
          </div>

          <div className="w-full mt-4">
            <label className="block font-bold mb-1">Description</label>
            <textarea
              value={data.description}
              onChange={e => setData('description', e.target.value)}
              rows="4"
              className="w-full rounded-md border-2 border-black p-[10px] font-bold shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] outline-none transition-all focus:translate-x-[3px] focus:translate-y-[3px] focus:shadow-none"
            />
            {errors.description && <div className="text-orange font-bold mt-1">{errors.description}</div>}
          </div>

          <div className="flex w-full gap-x-4 mt-8 items-start">
            <div className="w-1/2">
              <h4 className="font-bold mb-4 underline">Periods</h4>
              
              {data.periods_attributes.map((period, index) => (
                <div key={index} className="mb-4 p-2 border-2 border-black rounded-md bg-white">
                  <label className="block text-sm font-bold mb-1 text-gray-700">Start at</label>
                  <div className="flex gap-x-2">
                    <input
                      type="datetime-local"
                      value={period.start_at}
                      onChange={(e) => updatePeriod(index, e.target.value)}
                      className="w-10/12 rounded-md border-2 border-black p-1 outline-none"
                    />
                    <Button
                      type="button"
                      size="sm"
                      variant="neutral"
                      onClick={() => removePeriod(index)}
                      className="w-2/12 text-red-500"
                    >
                      X
                    </Button>
                  </div>
                  {errors[`periods_attributes.${index}.start_at`] && (
                    <div className="text-orange text-xs font-bold mt-1">
                      {errors[`periods_attributes.${index}.start_at`]}
                    </div>
                  )}
                </div>
              ))}

              <Button type="button" size="sm" variant="neutral" onClick={addPeriod} className="mt-2">
                + Add period
              </Button>
            </div>

            <div className="w-1/2">
              <h4 className="font-bold mb-4 underline">Tags</h4>
              
              {data.taggings_attributes.map((tagging, index) => (
                <div key={index} className="mb-4 p-2 border-2 border-black rounded-md bg-white">
                  <label className="block text-sm font-bold mb-1 text-gray-700">
                    Tag <span className="text-xs font-normal">(select or type new)</span>
                  </label>
                  
                  <div className="flex gap-x-2">
                    <div className="w-10/12 relative">
                      <input
                        list={`tags-list-${index}`}
                        value={tagging.tag_attributes.name}
                        onChange={(e) => updateTag(index, e.target.value)}
                        className="w-full rounded-md border-2 border-black p-1 outline-none"
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
                    <div className="text-orange text-xs font-bold mt-1">
                      {errors[`taggings_attributes.${index}.tag_attributes.name`]}
                    </div>
                  )}
                </div>
              ))}

              <div className="flex justify-end mt-2">
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

