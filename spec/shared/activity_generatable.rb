RSpec.shared_examples "activity generatable" do |record_name|
  let(:record) { build(record_name) }

  it "calls expected service" do
    expect(ActivitiesSetup::Proxy).to receive(:call).with(record)

    record.save!
  end
end
