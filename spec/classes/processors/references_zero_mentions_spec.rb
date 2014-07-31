# Copyright (c) 2014 Public Library of Science

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'spec_helper'

describe Processors::ReferencesZeroMentions do
  include Spec::ProcessorHelper

  before do
    refs 'First', 'Second', 'Third', 'Fourth'
    body "#{cite(1)}...#{cite(2)}#{cite(3)}"
  end

  it "should include zero citations" do
    expect(result[:references]['ref-4'][:zero_mentions]).to eq true
  end

  it "should not include zero citations for cited works" do
    expect(result[:references]['ref-2'][:zero_mentions]).to be_falsey
  end

  it "should not include zero citations if they are cited on their own" do
    expect(result[:references]['ref-1'][:zero_mentions]).to be_falsey
  end

end
