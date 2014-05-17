require 'spec_helper'

describe Processors::CitationGroupPosition do
  include Spec::ProcessorHelper

  before do
    refs 'First'
  end

  it "should include the position of the context" do
    body "Some text #{cite(1)} More text"
    expect(result[:groups][0][:word_position]).to eq(3)
  end

  it "should deal with nested elements" do
    body "Some <b>text</b> <a>#{cite(1)}</a> More text"
    expect(result[:groups][0][:word_position]).to eq(3)
  end

end