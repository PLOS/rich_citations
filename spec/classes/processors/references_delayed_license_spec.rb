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

class A
  def aaa; puts "original"; end
end

describe Processors::ReferencesDelayedLicense do
  include Spec::ProcessorHelper

  before do
    refs 'First', 'Second'
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :doi, id:'10.111/111' }, 'ref-2' => { id_type: :doi, id:'10.222/222' } )
  end

  def stub_clock(difference)
    start = Time.new(2001,1,1, 12,00, 00)
    expect_any_instance_of(Processors::ReferencesDelayedLicense).to receive(:timestamp).and_return(start+difference)
    expect_any_instance_of(Processors::ReferencesLicense).to receive(:timestamp).and_return(start)
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
    expect(HttpUtilities).to receive(:post).ordered.and_return(first_licenses)

    expected_data = [{"type"=>"doi","id"=>"10.111/111"}].to_json
    expect(HttpUtilities).to receive(:post).with('http://howopenisit.org/lookup', expected_data, anything).ordered.and_return('{}')

    stub_clock(20.seconds)

    process
  end

  it "should not call the API twice if all licenses were matched on the first call" do
    first_licenses = { results: [make_license('10.222/222', 'test-license-2'), make_license('10.111/111', 'test-license-1') ]}.to_json
    expect(HttpUtilities).to receive(:post).once.and_return(first_licenses)

    process
  end

  it "should set licenses from the second run" do
    first_licenses = { results: [make_license('10.111/111', 'test-license-1') ]}.to_json
    expect(HttpUtilities).to receive(:post).ordered.and_return(first_licenses)

    second_licenses = { results: [make_license('10.222/222', 'test-license-2') ]}.to_json
    expect(HttpUtilities).to receive(:post).ordered.and_return(second_licenses)

    stub_clock(20.seconds)

    expect( result[:references]['ref-1'][:info][:license] ).to eq('test-license-1')
    expect( result[:references]['ref-2'][:info][:license] ).to eq('test-license-2')
  end

  it "should sleep if necessary" do
    first_licenses = { results: [make_license('10.111/111', 'test-license-1') ]}.to_json
    second_licenses = { results: [make_license('10.222/222', 'test-license-2') ]}.to_json
    allow(HttpUtilities).to receive(:post).and_return(first_licenses, second_licenses)

    stub_clock(0.5.seconds)
    expect_any_instance_of(Processors::ReferencesDelayedLicense).to receive(:sleep).with(1.5)

    process
  end

  it "should not sleep if enough time has already passed" do
    first_licenses = { results: [make_license('10.111/111', 'test-license-1') ]}.to_json
    second_licenses = { results: [make_license('10.222/222', 'test-license-2') ]}.to_json
    allow(HttpUtilities).to receive(:post).and_return(first_licenses, second_licenses)

    stub_clock(2.seconds)
    expect_any_instance_of(Processors::ReferencesDelayedLicense).not_to receive(:sleep)

    process
  end

end
