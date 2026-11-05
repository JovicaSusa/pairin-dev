import { Head } from "@inertiajs/react";
import PageHeader from "@/components/PageHeader";
import ApplicationForm from "@/components/ApplicationForm";

export default function New({ pairRequest, applicationOptions, needsLevel, viaShareLink }) {
  return (
    <div className="mx-auto w-full max-w-2xl px-4 pb-16 md:px-8">
      <Head title="Send application" />

      <PageHeader eyebrow="Apply" title={pairRequest.subject} description={pairRequest.description} />

      <ApplicationForm
        pairRequest={pairRequest}
        options={applicationOptions}
        needsLevel={needsLevel}
        viaShareLink={viaShareLink}
        onSuccess={() => {}}
      />
    </div>
  );
}
