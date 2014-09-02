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

describe Processors::ReferencesInfoCacheLoader do
  include Spec::ProcessorHelper

  before do
    PaperInfoCache.delete_all
  end

  it "should load info from the cache if it exists" do
    refs 'First'
    PaperInfoCache.create!(identifier:'doi:10.111/111', bibliographic:{id_type: :doi, id:'10.111/111', id_source:'other', license:'cached' } )

    expect(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :doi, id:'10.111/111', id_source:'test' })

    process

    expect(result[:references]['ref-1'][:bibliographic]).to eq(id_type: :doi, id:'10.111/111', id_source:"test", license:'cached')
  end

  it "Should do nothing if there was no cache record" do
    refs 'First'
    expect(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :doi, id:'10.111/111', id_source:'test' })

    process

    expect(result[:references]['ref-1'][:bibliographic]).to eq(id_type: :doi, id:'10.111/111', id_source:'test')
  end

end
