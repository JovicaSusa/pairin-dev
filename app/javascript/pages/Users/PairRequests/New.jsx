import { useForm, Head } from '@inertiajs/react';
import PageHeader from "@/components/PageHeader";
import PairRequestForm from "./Form";

export default function New({ tags, commitments }) {
  const { data, setData, post, processing, errors } = useForm({
    subject: '',
    commitment: 'one_to_three_months',
    description: '',
    taggings_attributes: [{ tag_attributes: { name: '' } }]
  })

  const handleSubmit = (e) => {
    e.preventDefault()
    post('/users/pair_requests');
  }

  return (
    <div className="mx-auto w-full max-w-3xl px-4 pb-16 md:px-8">
      <Head title="Start a partner search" />

      <PageHeader
        eyebrow="Partner searches"
        title="Start a partner search"
        description="Say what you want to learn and how long you'd like to commit."
      />

      <PairRequestForm
        data={data}
        setData={setData}
        errors={errors}
        processing={processing}
        tags={tags}
        commitments={commitments}
        onSubmit={handleSubmit}
        submitLabel="Post partner search"
        processingLabel="Creating..."
      />
    </div>
  );
}
