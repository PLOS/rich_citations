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

describe Processors::ReferencesInfoCacheSaver do
  include Spec::ProcessorHelper

  before do
    PaperInfoCache.delete_all
    allow(Processors::ReferencesInfoCacheSaver).to receive(:dependencies).and_return( [Processors::ReferencesIdentifier] )
  end

  it "Create a cache record if non exists" do
    refs 'First'
    expect(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { uri_type: :doi, uri:'10.111/111', uri_source:'test', attribute:1.23 })

    process

    cache = PaperInfoCache.first
    expect(cache.identifier).to eq('doi:10.111/111')
    expect(cache.bibliographic).to        eq({attribute:1.23} )
  end

  it "Update an existing cache record" do
    cache = PaperInfoCache.create!(identifier:'doi:10.111/111', bibliographic:{uri_type: :doi, uri:'10.111/111', uri_source:'other', other:999 } )

    refs 'First'
    expect(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { uri_type: :doi, uri:'10.111/111', uri_source:'test', attribute:1.23 })

    process

    cache.reload
    expect(cache.identifier).to eq('doi:10.111/111')
    expect(cache.bibliographic).to        eq({attribute:1.23} )
  end

end
