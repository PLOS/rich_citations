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
describe Processors::ReferencesInfoFromUrl do
  include Spec::ProcessorHelper

  before do
    refs 'First'
  end

  def ref_info
    result[:references].first[:bibliographic]
  end

  it "should not parse the URL if there are cached results" do
    cached = { references: [
        {id:'ref-1', uri_type: :url, uri:'http://foo.com',accessed_at:Date.new(2012,1,13), bibliographic:{bib_source:'cached', title:'cached title', URL:'cached url'} },
    ] }
    process(cached)

    expect(ref_info[:bib_source]).to eq('cached')
    expect(ref_info[:title] ).to eq('cached title')
    expect(ref_info[:URL] ).to eq('cached url')
  end

  it "should merge in the parsed url results" do
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { uri_type: :url,  uri:'http://foo.com', score:1.23, attribute:'test' } )

    allow(HttpUtilities).to receive(:get).and_return({})

    expect(ref_info).to eq({
                              attribute:           'test',
                              bib_source:          'url',
                              URL:                 'http://foo.com',
                           })
  end

  it "should merge in the parsed url results" do
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { uri_type: :url,  uri:'http://foo.com', accessed_at:Date.new(2012,1,13), attribute:1.23, uri_source:'test' } )

    allow(HttpUtilities).to receive(:get).and_return({})
    expect(ref_info).to eq({
                               attribute:           1.23,
                               bib_source:          'url',
                               URL:                 'http://foo.com',
                               accessed:            { "date-parts" => [[2012, 1, 13]] }
                           })
  end

end
