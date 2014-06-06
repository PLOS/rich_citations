require 'spec_helper'

describe Processors::ReferencesAbstract do
  include Spec::ProcessorHelper

  it "should query the plos search API" do
    expect(Plos::Api).to receive(:search_dois).with(['10.1371/11111','10.1371/33333']).and_return([])

    input = { references: {
      'ref-1' => { doi:'10.1371/11111'},
      'ref-2' => { doi:'10.9999/22222'},
      'ref-3' => { doi:'10.1371/33333'},
    } }
    process(input)
  end

  it "should add abstracts" do
    search_results = [
      { 'abstract' => [' abstract 1 '] },
      { 'abstract' => [' abstract 2 '] },
    ]
    expect(Plos::Api).to receive(:search_dois).and_return( search_results )

    input = { references: {
        'ref-1' => { doi:'10.1371/11111'},
        'ref-2' => { doi:'10.9999/22222'},
        'ref-3' => { doi:'10.1371/33333'},
    } }
    process(input)

    expect(result[:references]['ref-1'][:info][:abstract]).to eq('abstract 1')
    expect(result[:references]['ref-3'][:info][:abstract]).to eq('abstract 2')
  end

  it "should not query the API if the abstract is cached" do
    search_results = [
        { 'abstract' => [' abstract 2 '] },
    ]
    expect(Plos::Api).to receive(:search_dois).with(['10.1371/22222']).and_return( search_results )

    cached = { references: {
        'ref-1' => { doi:'10.1371/11111', info:{abstract:'cached-1'} },
        'ref-2' => { doi:'10.1371/22222' },
    } }
    process(cached)

    expect(result[:references]['ref-1'][:info][:abstract]).to eq('cached-1')
    expect(result[:references]['ref-2'][:info][:abstract]).to eq('abstract 2')
  end

end