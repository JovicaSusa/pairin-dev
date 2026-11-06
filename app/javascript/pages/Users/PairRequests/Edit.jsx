import { useForm, Head } from '@inertiajs/react';
import PageHeader from "@/components/PageHeader";
import PairRequestForm from "./Form";

export default function Edit({ pairRequest, tags, commitments }) {
  const { data, setData, patch, processing, errors } = useForm({
    subject: pairRequest.subject,
    commitment: pairRequest.commitment,
    description: pairRequest.description,
    taggings_attributes: pairRequest.taggings.map(({ id, name }) => ({ id, tag_attributes: { name } }))
  })

  const handleSubmit = (e) => {
    e.preventDefault()
    patch(`/users/pair_requests/${pairRequest.id}`);
  }

  return (
    <div className="mx-auto w-full max-w-3xl px-4 pb-16 md:px-8">
      <Head title="Edit partner search" />

      <PageHeader
        eyebrow="Partner searches"
        title="Edit partner search"
        description="Applications you've already had stay as they are, and your share link doesn't change."
      />

      <PairRequestForm
        data={data}
        setData={setData}
        errors={errors}
        processing={processing}
        tags={tags}
        commitments={commitments}
        onSubmit={handleSubmit}
        submitLabel="Save changes"
        processingLabel="Saving..."
      />
    </div>
  );
}
