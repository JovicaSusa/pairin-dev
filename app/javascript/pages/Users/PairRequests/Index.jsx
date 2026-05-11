import { Head } from '@inertiajs/react';
import Card from './Card';

export default function Index({ pairRequests }) {
  return (
    <div className="flex justify-center">
      <Head title="Your Requests" />

      <div className="w-full md:w-3/4 xl:w-4/6 2xl:w-1/2">
        <div className="flex w-full flex-wrap items-center justify-center mt-12 pb-8 border-b-4 border-black border-dashed">
          <h3 className="w-full text-5xl font-bold">Your requests</h3>
        </div>

        <div className="mt-12">
          {pairRequests && pairRequests.length > 0 ? (
            pairRequests.map((request) => (
              <Card key={request.id} request={request} />
            ))
          ) : (
            <div className="text-center py-20 bg-white border-4 border-black border-dashed rounded-lg">
              <p className="text-xl font-bold">You haven't opened any requests yet.</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

