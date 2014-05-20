require 'spec_helper'

describe Processors::CitationGroupContext do
  include Spec::ProcessorHelper

  before do
    refs 'First', 'Second', 'Third', 'Fourth', 'Fifth', 'Sixth'
  end

  it "should provide citation context" do
    body "Some text #{cite(1)} More text"
    expect(result[:groups][0][:context]).to eq('Some text [1] More text')
  end

  it "should provide the correct text for a group with multiple references context" do
    body "  Some text #{cite(1)}, #{cite(3)} - #{cite(5)} More text  "
    expect(result[:groups][0][:context]).to eq('Some text [1], [3] - [5] More text')
  end

  it "should truncate ellipses" do
    before = (1..25).to_a.reverse.join(" ")
    after  = (1..15).to_a.join(" ")
    body "#{before} #{cite(1)} #{after}."
    expected_before = (1..20).to_a.reverse.join(" ")
    expected_after  = (1..10).to_a.join(" ")
    expect(result[:groups][0][:context]).to eq("\u2026#{expected_before} [1] #{expected_after}\u2026")
  end

  it "should be limited to the nearest section" do
    body "<sec>abc<sec>"
    body "Some text #{cite(1)} More text"
    body "</sec>def</sec>"
    expect(result[:groups][0][:context]).to eq('Some text [1] More text')
  end

  it "should be limited to the nearest paragraph" do
    body "<sec>abc<P>"
    body "Some text #{cite(1)} More text"
    body "</P>def</sec>"
    expect(result[:groups][0][:context]).to eq('Some text [1] More text')
  end

end