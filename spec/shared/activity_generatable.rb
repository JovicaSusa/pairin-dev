RSpec.shared_examples "activity generatable" do |record_name|
  let(:record) { build(record_name) }

  it "calls expected service" do
    expect(ActivitiesGenerationJob)
      .to receive(:perform_later)
      .with(record, instance_of(ActiveSupport::HashWithIndifferentAccess))

    record.save!
  end
end
