require 'spec_helper'

describe Processors::ReferencesDelayedLicense do
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

  it "should only call the API for unmatched licenses" do
    first_licenses = { results: [make_license('10.222/222', 'test-license-2') ]}.to_json
    expect(Plos::Api).to receive(:http_post).ordered.and_return(first_licenses)

    expected_data = [{"type"=>"doi","id"=>"10.111/111"}].to_json
    expect(Plos::Api).to receive(:http_post).with('http://howopenisit.org/lookup/12345,67890', expected_data, anything).ordered.and_return('{}')

    process
  end

  it "should not call the API twice if all licenses were matched on the first call" do
    first_licenses = { results: [make_license('10.222/222', 'test-license-2'), make_license('10.111/111', 'test-license-1') ]}.to_json
    expect(Plos::Api).to receive(:http_post).once.and_return(first_licenses)

    process
  end

  it "should set licenses from the second run" do
    first_licenses = { results: [make_license('10.111/111', 'test-license-1') ]}.to_json
    expect(Plos::Api).to receive(:http_post).ordered.and_return(first_licenses)

    second_licenses = { results: [make_license('10.222/222', 'test-license-2') ]}.to_json
    expect(Plos::Api).to receive(:http_post).ordered.and_return(second_licenses)

    expect( result[:references]['ref-1'][:info][:license] ).to eq('test-license-1')
    expect( result[:references]['ref-2'][:info][:license] ).to eq('test-license-2')
  end

end