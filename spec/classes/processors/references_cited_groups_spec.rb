require 'spec_helper'

describe Processors::ReferencesCitedGroups do
  include Spec::ProcessorHelper

  before do
    refs 'First', 'Second', 'Third', 'Fourth'
    body "#{cite(1)},#{cite(2)} ... #{cite(2)},#{cite(3)}"

    @refs   = result[:references]
    @groups = result[:groups]
  end

  it "return the correct citation groups" do
    expect(@refs[1][:citation_groups]).to eq [ @groups.first ]
    expect(@refs[2][:citation_groups]).to eq [ @groups.first, @groups.second ]
    expect(@refs[3][:citation_groups]).to eq [ @groups.second ]
  end

  it "returns nil if there are no groups" do
    expect(@refs[4][:citation_groups]).to be_nil
  end

end