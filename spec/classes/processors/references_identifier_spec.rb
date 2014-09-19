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

describe Processors::ReferencesIdentifier do
  include Spec::ProcessorHelper

  it "should include info in references" do
    refs 'Some Reference', 'Another Reference'

    expect(result[:references].count).to eq(2)
    expect(result[:references].first[:bibliographic]).to eq({text: "Some Reference"},    )
    expect(result[:references].second[:bibliographic]).to eq({text: "Another Reference"}  )
  end

  it "should include a doi in references" do
    refs 'Some Reference', 'Another Reference'
    expect(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { uri_type: :doi, uri:'10.12345/12345', uri_source:'test', attribute:1.23 })

    expect(result[:references].first[:uri_source]).to eq('test')
    expect(result[:references].first[:uri_type]).to eq(:doi)
    expect(result[:references].first[:uri]).to eq('10.12345/12345')
    expect(result[:references].first[:bibliographic]).to eq(attribute:1.23)
  end

  it "should remove nil info entries during cleanup" do
    cleanup( { references: [
        {id:'ref1', bibliographic: { a:1, b:nil, c:3} }
    ] } )

    expect(result[:references].first).to eq( id:'ref1', bibliographic: { a:1, c:3 } )
  end

  it "should remove nil info during cleanup" do
    cleanup( { references: [
        {id:'ref1', a:1, bibliographic: { b:nil} }
    ] } )

    expect(result[:references].first).to eq( { id:'ref1', a:1 } )
  end

end
