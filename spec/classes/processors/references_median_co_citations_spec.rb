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
