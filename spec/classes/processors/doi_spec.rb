require 'spec_helper'

describe Processors::Doi do
  include Spec::ProcessorHelper

  it "should have a DOI" do
    doi '10.12345/1234.12345'
    expect(result).to include(id_type: :doi, id:'10.12345/1234.12345')
  end

end