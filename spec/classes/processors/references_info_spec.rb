require 'spec_helper'

describe Processors::ReferencesInfo do
  include Spec::ProcessorHelper

  it "should include info in references" do
    refs 'Some Reference', 'Another Reference'

    expect(result[:references]).to have(2).items
    expect(result[:references][1][:info]).to eq({text: "Some Reference"},    )
    expect(result[:references][2][:info]).to eq({text: "Another Reference"}  )
  end

  it "should include a doi in references" do
    refs 'Some Reference', 'Another Reference'
    expect(ReferenceResolver).to receive(:resolve).and_return(1 => { doi:'10.12345/12345' })

    expect(result[:references][1][:doi]).to eq('10.12345/12345')
  end

end