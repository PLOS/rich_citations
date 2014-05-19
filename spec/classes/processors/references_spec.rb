require 'spec_helper'

describe Processors::References do
  include Spec::ProcessorHelper

  it "should have references" do
    refs 'Some Reference', 'Another Reference'

    expect(result[:references]).to have(2).items
    expect(result[:references]['ref-1']).to eq(id:'ref-1', index:1 )
    expect(result[:references]['ref-2']).to eq(id:'ref-2', index:2 )
  end

  it "should remove nil items during cleanup" do
    cleanup( { references: {
               ref1: { a:1, b:nil, c:3}
             } } )

    expect(result[:references]).to eq( ref1: { a:1, c:3 } )
  end

end