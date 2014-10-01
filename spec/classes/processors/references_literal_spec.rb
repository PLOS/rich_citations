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

describe Processors::ReferencesLiteral do
  include Spec::ProcessorHelper

  before do
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { uri_type: :doi, uri:'10.111/111' }, 'ref-2' => { uri_type: :doi, uri:'10.222/222', attribute:'test' })
  end

  it "should add the literal value of the reference" do
    refs 'First Reference'
    expect( result[:references].first[:original_citation] ).to eq('First Reference')
  end

  it "should handle tags appropriately" do
    refs 'text <b>bold</b> <span>removed</span>'
    expect( result[:references].first[:original_citation] ).to eq('text <strong>bold</strong> removed')
  end

  it "should remove the label" do
    refs '<label>1</label> Citation Text'
    expect( result[:references].first[:original_citation] ).to eq('Citation Text')
  end

end
