require 'spec_helper'

describe Processors::ReferencesMedianCoCitations do
  include Spec::ProcessorHelper

  before do
    refs 'First', 'Second', 'Third'
  end

  it "should include median co citations" do
    body "#{cite(1)},#{cite(2)}#{cite(3)} ... #{cite(2)},#{cite(1)}#{cite(3)}"
    expect(result[:references]['ref-2'][:median_co_citations]).to eq 2
  end

  it "should exclude itself" do
    body "#{cite(1)}"
    expect(result[:references]['ref-1'][:median_co_citations]).to eq 0
  end

  it "should not be present if it is not cited" do
    body "#{cite(1)}"
    expect(result[:references]['ref-3'][:median_co_citations]).to be_nil
  end

end