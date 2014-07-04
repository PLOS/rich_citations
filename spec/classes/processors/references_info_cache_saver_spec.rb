require 'spec_helper'

describe Processors::ReferencesInfoCacheSaver do
  include Spec::ProcessorHelper

  before do
    PaperInfoCache.delete_all
    allow(Processors::ReferencesInfoCacheSaver).to receive(:dependencies).and_return( [Processors::ReferencesIdentifier] )
  end

  it "Create a cache record if non exists" do
    refs 'First'
    expect(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :doi, id:'10.111/111', ref_source:'test', score:1.23 })

    process

    cache = PaperInfoCache.first
    expect(cache.identifier).to eq('doi:10.111/111')
    expect(cache.info).to        eq({id_type: 'doi', id:'10.111/111', ref_source:"test", score:1.23} )
  end

  it "Update an existing cache record" do
    cache = PaperInfoCache.create!(identifier:'doi:10.111/111', info:{id_type: :doi, id:'10.111/111', ref_source:'other', other:999 } )

    refs 'First'
    expect(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :doi, id:'10.111/111', ref_source:'test', score:1.23 })

    process

    cache.reload
    expect(cache.identifier).to eq('doi:10.111/111')
    expect(cache.info).to        eq({id_type: 'doi', id:'10.111/111', ref_source:"test", score:1.23} )
  end

end