require "rails_helper"

RSpec.describe SharedLink do
  def link(url)
    described_class.new(url:).tap(&:validate)
  end

  it "takes web links" do
    expect(link("https://github.com/maya/notes").errors[:url]).to be_empty
    expect(link("http://example.com").errors[:url]).to be_empty
  end

  it "refuses anything that isn't a web link" do
    expect(link("javascript:alert(1)").errors[:url]).to include("must start with http:// or https://")
    expect(link("example.com").errors[:url]).to include("must start with http:// or https://")
    expect(link("ftp://example.com/file").errors[:url]).to include("must start with http:// or https://")
    expect(link("https://").errors[:url]).to include("must start with http:// or https://")
    expect(link("https://exa mple.com").errors[:url]).to include("isn't a valid link")
    expect(link("").errors[:url]).to include("can't be blank")
  end

  it "trims the link and drops an empty note" do
    shared = described_class.new(url: "  https://www.github.com/x  ", note: "   ")

    expect(shared.url).to eq("https://www.github.com/x")
    expect(shared.note).to be_nil
    expect(shared.host).to eq("github.com")
  end
end
