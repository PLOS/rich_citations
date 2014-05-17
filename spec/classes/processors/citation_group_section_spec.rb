require 'spec_helper'

describe Processors::CitationGroupSection do
  include Spec::ProcessorHelper

  before do
    refs 'First'
  end

  it "should include the section title" do
    body "<sec><title>Title 1</title>Some text #{cite(1)} More text<sec>"
    expect(result[:groups][0][:section]).to eq('Title 1')
  end

  it "should include the outermost section title" do
    body "<sec><title>Title 1</title>"
    body "<sec><title>Title 2</title>Some text #{cite(1)} More text</sec>"
    body "</sec>"
    expect(result[:groups][0][:section]).to eq('Title 1')
  end

  it "should include the outermost section that has a title" do
    body "<sec>"
    body "<sec><title>Title 2</title>Some text #{cite(1)} More text</sec>"
    body "</sec>"
    expect(result[:groups][0][:section]).to eq('Title 2')
  end

  it "should include nothing if there is no section" do
    body "<p><title>Title 2</title>Some text #{cite(1)} More text</p>"
    expect(result[:groups][0][:section]).to eq('[Unknown]')
  end

  it "should include nothing if the section has no title" do
    body "<sec>Some text #{cite(1)} More text</sec>"
    expect(result[:groups][0][:section]).to eq('[Unknown]')
  end

end