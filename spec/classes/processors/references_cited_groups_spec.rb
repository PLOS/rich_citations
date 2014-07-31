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

describe Processors::ReferencesCitedGroups do
  include Spec::ProcessorHelper

  before do
    refs 'First', 'Second', 'Third', 'Fourth'
    body "#{cite(1)},#{cite(2)} ... #{cite(2)},#{cite(3)}"

    @refs   = result[:references]
    @groups = result[:groups]
  end

  it "return the correct citation groups" do
    expect(@refs['ref-1'][:citation_groups]).to eq [ @groups.first ]
    expect(@refs['ref-2'][:citation_groups]).to eq [ @groups.first, @groups.second ]
    expect(@refs['ref-3'][:citation_groups]).to eq [ @groups.second ]
  end

  it "returns nil if there are no groups" do
    expect(@refs['ref-4'][:citation_groups]).to be_nil
  end

end
