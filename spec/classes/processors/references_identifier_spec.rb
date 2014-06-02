require 'spec_helper'

describe Processors::ReferencesIdentifier do
  include Spec::ProcessorHelper

  it "should include info in references" do
    refs 'Some Reference', 'Another Reference'

    expect(result[:references]).to have(2).items
    expect(result[:references]['ref-1'][:info]).to eq({text: "Some Reference"},    )
    expect(result[:references]['ref-2'][:info]).to eq({text: "Another Reference"}  )
  end

  it "should include a doi in references" do
    refs 'Some Reference', 'Another Reference'
    expect(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { doi:'10.12345/12345' })

    expect(result[:references]['ref-1'][:doi]).to eq('10.12345/12345')
  end

  it "should remove nil info entries during cleanup" do
    cleanup( { references: {
        ref1: { info: { a:1, b:nil, c:3} }
    } } )

    expect(result[:references][:ref1]).to eq( info: { a:1, c:3 } )
  end

  it "should remove nil info during cleanup" do
    cleanup( { references: {
        ref1: { a:1, info: { b:nil} }
    } } )

    expect(result[:references][:ref1]).to eq( { a:1 } )
  end

end