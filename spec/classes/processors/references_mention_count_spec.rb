require 'spec_helper'

describe Processors::ReferencesMentionCount do
  include Spec::ProcessorHelper

  before do
    refs 'First', 'Second', 'Third'
  end

  it "should have the correct mention counts" do
    body "#{cite(1)},#{cite(2)} ... #{cite(2)},#{cite(3)}"
    expect(result[:references][1][:mentions]).to eq 1
    expect(result[:references][2][:mentions]).to eq 2
    expect(result[:references][3][:mentions]).to eq 1
  end

end