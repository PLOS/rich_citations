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

describe Processors::ReferencesInfoFromDoi do
  include Spec::ProcessorHelper

  it "should call the API" do
    refs 'First', 'Secpmd', 'Third'
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { uri_type: :doi, uri:'10.111/111' },
                                                              'ref-2' => { source:'none'},
                                                              'ref-3' => { uri_type: :doi, uri:'10.333/333' })

    expect(HttpUtilities).to receive(:get).with('http://dx.doi.org/10.111%2F111', anything).and_return('{}')
    expect(HttpUtilities).to receive(:get).with('http://dx.doi.org/10.333%2F333', anything).and_return('{}')

    process
  end

  it "should merge in the API results" do
    refs 'First', 'Secpmd', 'Third'
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { uri_type: :doi, uri:'10.111/111', score:1.23, source:'test' } )

    info = {
        author:  [ {given:'C.', family:'Theron'} ],
        title:   'A Title',
    }
    expect(HttpUtilities).to receive(:get).with('http://dx.doi.org/10.111%2F111', anything).and_return(JSON.generate(info))

    expect(result[:references]['ref-1'][:bibliographic]).to eq({
                                                          uri:         '10.111/111',
                                                          uri_type:    :doi,
                                                          source:      'test',
                                                          info_source: 'dx.doi.org',
                                                          score:       1.23,
                                                          author:      [ {given:'C.', family:'Theron'} ],
                                                          title:       'A Title',
                                                      })
  end

  it "should not call the API if there are cached results" do
    refs 'First'
    expect(HttpUtilities).to_not receive(:get)

    cached = { references: {
        'ref-1' => { uri_type: :doi, uri:'10.1371/11111', bibliographic:{info_source:'cached', title:'cached title'} },
    } }
    process(cached)

    expect(result[:references]['ref-1'][:bibliographic][:info_source] ).to eq('cached')
    expect(result[:references]['ref-1'][:bibliographic][:title]).to eq('cached title')
  end

  it "should not overwrite the uri_type, uri, score, info_source or uri_source" do
    refs 'First', 'Secpmd', 'Third'
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { uri_type: :doi, uri:'10.111/111', score:1.23, uri_source:'test' } )

    info = {
        uri:         '10.xxx/xxx',
        uri_type:    :foo,
        score:       99,
        uri_source:  'ignored',
        info_source: 'ignored',
    }
    expect(HttpUtilities).to receive(:get).with('http://dx.doi.org/10.111%2F111', anything).and_return(JSON.generate(info))

    expect(result[:references]['ref-1'][:bibliographic]).to eq({
                                                          uri_type:    :doi,
                                                          uri:         '10.111/111',
                                                          uri_source:  'test',
                                                          info_source: 'dx.doi.org',
                                                          score:       1.23,
                                                      })
  end

  it "handles a missing/bad doi" do
    refs 'Some Reference'

    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { uri_type: :doi, uri:'10.111/111' } )
    expect(HttpUtilities).to receive(:get).with('http://dx.doi.org/10.111%2F111', anything).and_raise(Net::HTTPServerException.new(404, Net::HTTPNotFound.new(nil, 404, '') ))

    process

  end

end
