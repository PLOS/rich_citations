require 'spec_helper'

describe Processors::ReferencesAbstract do
  include Spec::ProcessorHelper

  it "should query the plos search API" do
    expected_query = 'q=id:("10.1371%2F11111"+OR+"10.1371%2F33333")'
    expect(Plos::Api).to receive(:http_post).with(anything, expected_query, anything).and_return('{"response":{"docs":[]}}')

    input = { references: {
      'ref-1' => { doi:'10.1371/11111'},
      'ref-2' => { doi:'10.9999/22222'},
      'ref-3' => { doi:'10.1371/33333'},
    } }
    process(input)
  end

  it "should add abstracts" do
    json = { response: { docs: [
      { abstract: [' abstract 1 '] },
      { abstract: [' abstract 2 '] },
    ] } }
    expect(Plos::Api).to receive(:http_post).and_return( JSON.generate(json) )

    input = { references: {
        'ref-1' => { doi:'10.1371/11111'},
        'ref-2' => { doi:'10.9999/22222'},
        'ref-3' => { doi:'10.1371/33333'},
    } }
    process(input)

    expect(result[:references]['ref-1'][:info][:abstract]).to eq('abstract 1')
    expect(result[:references]['ref-3'][:info][:abstract]).to eq('abstract 2')
  end

end