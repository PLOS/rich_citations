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

describe Processors::ReferencesLicense do
  include Spec::ProcessorHelper

  before do
    refs 'First', 'Second'
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { uri_type: :doi, uri:'10.111/111' }, 'ref-2' => { uri_type: :doi, uri:'10.222/222', attribute:'test' })
  end

  def make_license(doi, type, status='active', date=Time.now)
    {
        identifier:[
                       {type:'doi', id:doi}
                   ],
        license:[{status:status,
                  type:type,
                  provenance:{date:date.as_json}
                 }]
    }
  end

  it "should call the API" do
    expected_data = [{"type"=>"doi","id"=>"10.111/111"},{"type"=>"doi","id"=>"10.222/222"}].to_json
    expect(HttpUtilities).to receive(:post).with('http://howopenisit.org/lookup', expected_data, anything).and_return('{}')
    process
  end

  it "should add the license" do
    licenses = { results: [make_license('10.222/222', 'test-license-2'), make_license('10.111/111', 'test-license-1')]}
    expect(HttpUtilities).to receive(:post).and_return(JSON.generate(licenses))
    expect( result[:references]['ref-1'][:bibliographic][:license] ).to eq('test-license-1')
    expect( result[:references]['ref-2'][:bibliographic][:license] ).to eq('test-license-2')
  end

  it "should add inactive licenses license" do
    licenses = { results: [make_license('10.222/222', 'inactive-license-2', nil) ]}
    expect(HttpUtilities).to receive(:post).and_return(JSON.generate(licenses))
    expect( result[:references]['ref-2'][:bibliographic][:license] ).to eq('inactive-license-2')
  end

  it "should not set a license if no result is returned" do
    licenses = { results: []}
    expect(HttpUtilities).to receive(:post).and_return(JSON.generate(licenses))
    expect( result[:references]['ref-2'][:bibliographic][:license] ).to be_nil
  end

  it "should choose from multiple returned identifiers" do
    license  = {
        identifier:[
                       {type:'doi', id:'10.333/333'},
                       {type:'doi', id:'10.222/222'}
                   ],
        license:[{status:'active',
                  type:'test-license',
                  provenance:{date:Time.now.as_json}
                 }]
    }
    licenses = { results: [license]}
    expect(HttpUtilities).to receive(:post).and_return(JSON.generate(licenses))
    expect( result[:references]['ref-2'][:bibliographic][:license] ).to eq('test-license')
  end

  it "should choose the most recent of multiple licenses" do
    license  = {
        identifier:[ {type:'doi', id:'10.222/222'} ],
        license:[
          {status:'active',type:'test-license-1', provenance:{date: 3.days.ago.as_json} },
          {status:'active',type:'test-license-2', provenance:{date: 2.days.ago.as_json} },
          {status:'active',type:'test-license-3', provenance:{date: 4.days.ago.as_json} },
          ]
    }
    licenses = { results: [license]}
    expect(HttpUtilities).to receive(:post).and_return(JSON.generate(licenses))
    expect( result[:references]['ref-2'][:bibliographic][:license] ).to eq('test-license-2')
  end

  it "should prioritize active licenses over inactive ones" do
    license  = {
        identifier:[ {type:'doi', id:'10.222/222'} ],
        license:[
                       {status:'inactive',type:'inactive-license-1', provenance:{date: 2.days.ago.as_json} },
                       {status:'active',  type:'test-license-2',     provenance:{date: 4.days.ago.as_json} },
                   ]
    }
    licenses = { results: [license]}
    expect(HttpUtilities).to receive(:post).and_return(JSON.generate(licenses))
    expect( result[:references]['ref-2'][:bibliographic][:license] ).to eq('test-license-2')
  end

  it "should not call the API if the license was in the cache" do
    license  = {
        identifier:[ {type:'doi', id:'10.222/222'} ],
        license:[
                       {status:'inactive',type:'inactive-license-1', provenance:{date: 2.days.ago.as_json} },
                       {status:'active',  type:'test-license-2',     provenance:{date: 4.days.ago.as_json} },
                   ]
    }
    licenses = { results: [license]}
    expect(HttpUtilities).to receive(:post).with(anything, '[{"type":"doi","id":"10.222/222"}]', anything).and_return(JSON.generate(licenses))

    cached = { references: {
        'ref-1' => { uri_type: :doi, uri:'10.111/111', bibliographic:{license:'cached-license-1'} },
        'ref-2' => { uri_type: :doi, uri:'10.222/222', bibliographic:{}  },
    } }
    process(cached)

    expect( result[:references]['ref-1'][:bibliographic][:license] ).to eq('cached-license-1')
    expect( result[:references]['ref-2'][:bibliographic][:license] ).to eq('test-license-2')
  end

  it "should record the time of the run" do
    licenses = { results: [make_license('10.222/222', 'test-license-2'), make_license('10.111/111', 'test-license-1')]}
    allow(HttpUtilities).to receive(:post).and_return(JSON.generate(licenses))
    allow_any_instance_of(Processors::State).to receive(:cleanup) { }

    travel_to Time.new(2012, 6, 12, 1, 2, 3) do
      expect(result[:state].license_retrieved_time).to eq(Time.new(2012, 6, 12, 1, 2, 3))
    end
  end

end
