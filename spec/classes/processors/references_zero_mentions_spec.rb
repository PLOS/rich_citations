require 'spec_helper'

describe Processors::ReferencesZeroMentions do
  include Spec::ProcessorHelper

  before do
    refs 'First', 'Second', 'Third', 'Fourth'
    body "#{cite(1)}...#{cite(2)}#{cite(3)}"
  end

  it "should include zero citations" do
    expect(result[:references][4][:zero_mentions]).to eq true
  end

  it "should not include zero citations for cited works" do
    expect(result[:references][2][:zero_mentions]).to be_falsey
  end

  it "should not include zero citations if they are cited on their own" do
    expect(result[:references][1][:zero_mentions]).to be_falsey
  end

end