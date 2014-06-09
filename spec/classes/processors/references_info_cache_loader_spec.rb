require 'spec_helper'

describe Processors::ReferencesInfoCacheLoader do
  include Spec::ProcessorHelper

  before do
    PaperInfoCache.delete_all
  end

  it "should load info from the cache if it exists" do
    refs 'First'
    PaperInfoCache.create!(identifier:'doi:10.111/111', info:{doi:'10.111/111', source:'other', license:'cached' } )
    expect(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { doi:'10.111/111', source:'test' })

    process

    expect(result[:references]['ref-1'][:info]).to eq(doi:"10.111/111", source:"test", license:'cached')
  end

  it "Should do nothing if there was no cache record" do
    refs 'First'
    expect(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { doi:'10.111/111', source:'test' })

    process

    expect(result[:references]['ref-1'][:info]).to eq(doi:'10.111/111', source:'test')
  end

end