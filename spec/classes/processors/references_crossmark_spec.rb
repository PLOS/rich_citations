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

require "spec_helper"

describe Processors::ReferencesCrossmark do
  include Spec::ProcessorHelper

  it "should include info in references" do
    refs 'Some Reference'
    Rails.cache.delete("crossmark_10.111%2F111")

    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :doi, id:'10.111/111' } )
    expect(HttpUtilities).to receive(:get).with('http://crossmark.crossref.org/crossmark/?doi=10.111%2F111').and_return('
    {"updated_by": [
        {
          "doi": "10.5555/26262626x",
          "publication_year": 2012,
          "publication_month": 3,
          "publication_day": 15,
          "type": "interesting_update",
          "label": "Interesting Update",
          "date": "2012-03-15"
        }
      ]
    }')

    process
    expect(result[:references]['ref-1'][:updated_by][0][:doi]).to eq("10.5555/26262626x")
  end

  it "handles missing crossref" do
    refs 'Some Reference'
    Rails.cache.delete("crossmark_10.111%2F112")
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :doi, id:'10.111/112' } )
    expect(HttpUtilities).to receive(:get).with('http://crossmark.crossref.org/crossmark/?doi=10.111%2F112').and_raise(Net::HTTPServerException.new(404, Net::HTTPNotFound.new(nil, 404, '') ))
    process
  end
end
