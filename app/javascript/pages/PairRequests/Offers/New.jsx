import { Form, Head } from '@inertiajs/react';
import { formatShort } from "@/helpers/date";

export default function New({ pairRequestId, periods }) {
  return (
    <div className="flex flex-col items-center w-full px-4">
      <Head title="Send application" />
      <div className="w-full md:w-3/4 xl:w-4/6 2xl:w-1/2">
        <div className="flex w-full items-center mt-12 pb-8 border-b-4 border-black border-dashed text-center">
          <h3 className="text-5xl font-bold">Send application</h3>
        </div>

        <Form method="post" action={`/pair_requests/${pairRequestId}/offers`} className="flex flex-col items-start mt-12">
          {({ errors, processing }) => (
            <>
              <div className="w-full">
                <label className="block font-bold mb-1">Message</label>
                <textarea
                  name="message"
                  rows="4"
                  className="w-full rounded-md border-2 border-black p-[10px] font-bold shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] outline-none transition-all focus:translate-x-[3px] focus:translate-y-[3px] focus:shadow-none"
                />
                {errors.message && (
                  <div className="text-red-600 font-bold mt-1">{errors.message}</div>
                )}
              </div>

              <div className="w-full mt-4">
                <label className="block font-bold mb-1">Select period</label>
                <select
                  name="period_id"
                  defaultValue={periods[0]?.id || ''}
                  className="w-full rounded-md border-2 border-black p-[10px] font-bold shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] outline-none transition-all focus:translate-x-[3px] focus:translate-y-[3px] focus:shadow-none"
                >
                  {periods.map(period => (
                    <option key={period.id} value={period.id}>
                      {formatShort(period.start_at)} : {formatShort(period.end_at)}
                    </option>
                  ))}
                </select>
                {(errors.period || errors.period_id) && (
                  <div className="text-orange font-bold mt-1">{errors.period || errors.period_id}</div>
                )}
              </div>

              <div className="w-full flex justify-center">
                <button
                  type="submit"
                  disabled={processing}
                  className="mt-12 flex cursor-pointer items-center rounded-md border-2 border-black bg-purple px-10 py-3 font-bold shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] transition-all hover:translate-x-[3px] hover:translate-y-[3px] hover:shadow-none"
                >
                  {processing ? 'Sending...' : 'Apply'}
                </button>
              </div>
            </>
          )}
        </Form>
      </div>
    </div>
  );
}
