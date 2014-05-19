require 'spec_helper'

describe Processors::ReferencesSection do
  include Spec::ProcessorHelper

  before do
    refs 'First', 'Second', 'Third'
  end

  it "should be limited to the nearest paragraph" do
    body "<sec><title>Title 1</title>Some text #{cite(1)} More text<sec>"
    expect(result[:references]['ref-1'][:sections]).to eq('Title 1' => 1)
  end

end