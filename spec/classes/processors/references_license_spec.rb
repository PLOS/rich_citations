require 'spec_helper'

describe Processors::ReferencesLicense do
  include Spec::ProcessorHelper

  before do
    refs 'First', 'Second'
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { doi:'10.111/111' }, 'ref-2' => { doi:'10.222/222' })
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
    expect(Plos::Api).to receive(:http_post).with('http://howopenisit.org/lookup/12345,67890', expected_data, anything).and_return('{}')
    process
  end

  it "should add the license" do
    licenses = { results: [make_license('10.222/222', 'test-license-2'), make_license('10.111/111', 'test-license-1')]}
    expect(Plos::Api).to receive(:http_post).and_return(JSON.generate(licenses))
    expect( result[:references]['ref-1'][:info][:license] ).to eq('test-license-1')
    expect( result[:references]['ref-2'][:info][:license] ).to eq('test-license-2')
  end

  it "should add inactive licenses license" do
    licenses = { results: [make_license('10.222/222', 'inactive-license-2', nil) ]}
    expect(Plos::Api).to receive(:http_post).and_return(JSON.generate(licenses))
    expect( result[:references]['ref-2'][:info][:license] ).to eq('inactive-license-2')
  end

  it "should not set a license if no result is returned" do
    licenses = { results: []}
    expect(Plos::Api).to receive(:http_post).and_return(JSON.generate(licenses))
    expect( result[:references]['ref-2'][:info][:license] ).to be_nil
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
    expect(Plos::Api).to receive(:http_post).and_return(JSON.generate(licenses))
    expect( result[:references]['ref-2'][:info][:license] ).to eq('test-license')
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
    expect(Plos::Api).to receive(:http_post).and_return(JSON.generate(licenses))
    expect( result[:references]['ref-2'][:info][:license] ).to eq('test-license-2')
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
    expect(Plos::Api).to receive(:http_post).and_return(JSON.generate(licenses))
    expect( result[:references]['ref-2'][:info][:license] ).to eq('test-license-2')
  end

end