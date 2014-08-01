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

describe Processors::ReferencesAbstract do
  include Spec::ProcessorHelper

  it "should query the plos search API" do
    expect(Plos::Api).to receive(:search_dois).with(['10.1371/11111','10.1371/33333']).and_return([])

    input = { references: {
      'ref-1' => { id_type: :doi, id:'10.1371/11111'},
      'ref-2' => { id_type: :doi, id:'10.9999/22222'},
      'ref-3' => { id_type: :doi, id:'10.1371/33333'},
    } }
    process(input)
  end

  it "should add abstracts" do
    search_results = [
      { 'id' => '10.1371/11111',
        'abstract' => [' abstract 1 '] },
      { 'id' => '10.1371/33333',
        'abstract' => [' abstract 2 '] },
    ]
    expect(Plos::Api).to receive(:search_dois).and_return( search_results )

    input = { references: {
        'ref-1' => { id_type: :doi, id:'10.1371/11111'},
        'ref-2' => { id_type: :doi, id:'10.9999/22222'},
        'ref-3' => { id_type: :doi, id:'10.1371/33333'},
    } }
    process(input)

    expect(result[:references]['ref-1'][:info][:abstract]).to eq('abstract 1')
    expect(result[:references]['ref-3'][:info][:abstract]).to eq('abstract 2')
  end

  it "should not query the API if the abstract is cached" do
    search_results = [
      { 'id' => '10.1371/22222',
        'abstract' => [' abstract 2 '] },
    ]
    expect(Plos::Api).to receive(:search_dois).with(['10.1371/22222']).and_return( search_results )

    cached = { references: {
        'ref-1' => { id_type: :doi, id:'10.1371/11111', info:{abstract:'cached-1'} },
        'ref-2' => { id_type: :doi, id:'10.1371/22222' },
    } }
    process(cached)

    expect(result[:references]['ref-1'][:info][:abstract]).to eq('cached-1')
    expect(result[:references]['ref-2'][:info][:abstract]).to eq('abstract 2')
  end

  it 'should work if the API does not return a result for a DOI' do
    search_results = [
      { 'id' => '10.1371/22222',
        'abstract' => [' abstract 2 '] }
    ]

    expect(Plos::Api).to receive(:search_dois).with(['10.1371/11111', '10.1371/22222']).and_return(search_results)

    cached = { references: {
      'ref-1' => { id_type: :doi, id: '10.1371/11111' },
      'ref-2' => { id_type: :doi, id: '10.1371/22222' }
    } }
    process(cached)

    expect(result[:references]['ref-2'][:info][:abstract]).to eq('abstract 2')
  end

end
