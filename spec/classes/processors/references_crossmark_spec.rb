require "spec_helper"

describe Processors::ReferencesCrossmark do
  include Spec::ProcessorHelper

  it "should include info in references" do
    refs 'Some Reference'
    Rails.cache.delete("crossmark_10.111%2F111")
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { doi:'10.111/111' } )
    expect(Plos::Api).to receive(:http_get).with('http://crossmark.crossref.org/crossmark/?doi=10.111%2F111').and_return('
{"updated_by": [
    {
      "doi": "10.5555/26262626x",
      "publication_year": 2012,
      "publication_month": 3,
      "publication_day": 15,
      "type": "interesting_update",
      "label": "Interesting Update",
      "date": "2012-03-15"
    }
  ]
}')
    process
    expect(result[:references]['ref-1'][:updated_by][0][:doi]).to eq("10.5555/26262626x")
  end

  it "handles missing crossref" do
    refs 'Some Reference'
    Rails.cache.delete("crossmark_10.111%2F112")
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { doi:'10.111/112' } )
    expect(Plos::Api).to receive(:http_get).with('http://crossmark.crossref.org/crossmark/?doi=10.111%2F112').and_raise(Net::HTTPServerException.new(404, ""))
    process
  end
end
