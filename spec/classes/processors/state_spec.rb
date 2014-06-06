require 'spec_helper'

describe Processors::State do
  include Spec::ProcessorHelper

  it "should remove the state during cleanup" do
    cleanup( state: 'foo')
    expect(result).to eq( {} )
  end

end