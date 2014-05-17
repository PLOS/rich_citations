require 'spec_helper'

describe Resolvers::Doi do
  Resolver = Resolvers::Doi
  
  describe '#extract_doi' do

    it "should match a doi string" do
      expect( Resolver.extract_doi('doi:10.123/4567.890 ') ).to eq('10.123/4567.890')
      expect( Resolver.extract_doi('doi 10.123/4567.890 ') ).to eq('10.123/4567.890')
      expect( Resolver.extract_doi('dOi 10.123/4567.890 ') ).to eq('10.123/4567.890')
      expect( Resolver.extract_doi('DOI: 10.123/4567.890') ).to eq('10.123/4567.890')
      expect( Resolver.extract_doi(' doi:10.123/4567.890') ).to eq('10.123/4567.890')
    end

    it "should not match some similar strings" do
      expect( Resolver.extract_doi('xdoi:10.123/4567.890 ') ).to be_nil
      expect( Resolver.extract_doi('doi:11.123/4567.890 ') ).to be_nil
    end

    it "should trim trailing punctuation" do
      expect( Resolver.extract_doi('doi:10.123/4567.890. ') ).to eq('10.123/4567.890')
      expect( Resolver.extract_doi('doi:10.123/4567.890.') ).to eq('10.123/4567.890')
      expect( Resolver.extract_doi('doi:10.123/4567.890). ') ).to eq('10.123/4567.890')
      expect( Resolver.extract_doi('doi:10.123/4567.890" ') ).to eq('10.123/4567.890')
    end

    it "should match a doi url" do
      expect( Resolver.extract_doi('doi.org/10.123/4567.890 ') ).to eq('10.123/4567.890')
      expect( Resolver.extract_doi('dx.doi.org/10.123/4567.890 ') ).to eq('10.123/4567.890')
      expect( Resolver.extract_doi('dOi.ORG/10.123/4567.890') ).to eq('10.123/4567.890')
    end

    it "should unescape a DOI url" do
      expect( Resolver.extract_doi('doi.org/10.123/4+5%3D6%267%208. ') ).to eq('10.123/4 5=6&7 8')
    end

    it "prefers the URL doi to the inline DOI" do
      expect( Resolver.extract_doi('doi.org/10.123/4567.890 doi:10.123/9765.432 ') ).to eq('10.123/4567.890')
    end

    it "should not match some similar doi URLs" do
      expect( Resolver.extract_doi('xdoi.org/10.123/4567.890 ') ).to be_nil
      expect( Resolver.extract_doi('doi.org:10.123/4567.890 ') ).to be_nil
      expect( Resolver.extract_doi('doi.org/11.123/4567.890 ') ).to be_nil
    end

    it "should trim trailing punctuation in urls" do
      expect( Resolver.extract_doi('doi.org/10.123/4567.890. ') ).to eq('10.123/4567.890')
      expect( Resolver.extract_doi('doi.org/10.123/4567.890.') ).to eq('10.123/4567.890')
      expect( Resolver.extract_doi('doi.org/10.123/4567.890). ') ).to eq('10.123/4567.890')
      expect( Resolver.extract_doi('doi.org/10.123/4567.890" ') ).to eq('10.123/4567.890')
    end

  end

  describe '#extract_doi_list' do

    it "should extract a list of DOIs" do
      expect( Resolver.extract_doi_list("10.1/1.23") ).to eq([ '10.1/1.23' ])
    end

    it "should separate on whitespace" do
      expect( Resolver.extract_doi_list("10.1/1.01 10.1/1.02\t10.1/1.03\n10.1/1.04") ).to eq([ '10.1/1.01', '10.1/1.02', '10.1/1.03', '10.1/1.04' ])
    end

    it "should ignore stuff that doesn't look like a DOI" do
      expect( Resolver.extract_doi_list("10.1/1.01 -----\n10 sometext\n10.1/1.04") ).to eq([ '10.1/1.01', '10.1/1.04' ])
    end

    it "should remove white space, quotes and punctuation" do
      expect( Resolver.extract_doi_list('  "10.1/1.01",  --10.1/1.03  ') ).to eq([ '10.1/1.01', '10.1/1.03' ])
    end

  end

end
