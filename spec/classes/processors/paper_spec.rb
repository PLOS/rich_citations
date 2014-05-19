require 'spec_helper'

describe Processors::Paper do
  include Spec::ProcessorHelper

  it "should have a word count" do
    body 'here is <b>some</b> text'
    expect(result[:paper][:word_count]).to eq(4)
  end

end