require 'spec_helper'

describe Processors::References do
  include Spec::ProcessorHelper

  it "should have references" do
    refs 'Some Reference', 'Another Reference'

    expect(result[:references]).to have(2).items
    expect(result[:references][1]).to eq(id:'ref-1', info:{text: "Some Reference"},    )
    expect(result[:references][2]).to eq(id:'ref-2', info:{text: "Another Reference"}  )
  end

  it "should remove nil items during cleanup" do
    cleanup( { references: {
               ref1: { a:1, b:nil, c:3}
             } } )

    expect(result[:references]).to eq( ref1: { a:1, c:3 } )
  end

end