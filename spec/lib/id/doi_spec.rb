require 'spec_helper'

describe Id::Doi do
  
  describe '#extract' do

    it "should match a doi string" do
      expect( Id::Doi.extract('doi:10.123/4567.890 ') ).to eq('10.123/4567.890')
      expect( Id::Doi.extract('doi 10.123/4567.890 ') ).to eq('10.123/4567.890')
      expect( Id::Doi.extract('dOi 10.123/4567.890 ') ).to eq('10.123/4567.890')
      expect( Id::Doi.extract('DOI: 10.123/4567.890') ).to eq('10.123/4567.890')
      expect( Id::Doi.extract(' doi:10.123/4567.890') ).to eq('10.123/4567.890')
    end

    it "should not match some similar strings" do
      expect( Id::Doi.extract('xdoi:10.123/4567.890 ') ).to be_nil
      expect( Id::Doi.extract('doi:11.123/4567.890 ') ).to be_nil
    end

    it "should trim trailing punctuation" do
      expect( Id::Doi.extract('doi:10.123/4567.890. ') ).to eq('10.123/4567.890')
      expect( Id::Doi.extract('doi:10.123/4567.890.') ).to eq('10.123/4567.890')
      expect( Id::Doi.extract('doi:10.123/4567.890). ') ).to eq('10.123/4567.890')
      expect( Id::Doi.extract('doi:10.123/4567.890" ') ).to eq('10.123/4567.890')
    end

    it "should match a doi url" do
      expect( Id::Doi.extract('doi.org/10.123/4567.890 ') ).to eq('10.123/4567.890')
      expect( Id::Doi.extract('dx.doi.org/10.123/4567.890 ') ).to eq('10.123/4567.890')
      expect( Id::Doi.extract('dOi.ORG/10.123/4567.890') ).to eq('10.123/4567.890')
    end

    it "should unescape a DOI url" do
      expect( Id::Doi.extract('doi.org/10.123/4+5%3D6%267%208. ') ).to eq('10.123/4 5=6&7 8')
    end

    it "prefers the URL doi to the inline DOI" do
      expect( Id::Doi.extract('doi.org/10.123/4567.890 doi:10.123/9765.432 ') ).to eq('10.123/4567.890')
    end

    it "should not match some similar doi URLs" do
      expect( Id::Doi.extract('xdoi.org/10.123/4567.890 ') ).to be_nil
      expect( Id::Doi.extract('doi.org:10.123/4567.890 ') ).to be_nil
      expect( Id::Doi.extract('doi.org/11.123/4567.890 ') ).to be_nil
    end

    it "should trim trailing punctuation in urls" do
      expect( Id::Doi.extract('doi.org/10.123/4567.890. ') ).to eq('10.123/4567.890')
      expect( Id::Doi.extract('doi.org/10.123/4567.890.') ).to eq('10.123/4567.890')
      expect( Id::Doi.extract('doi.org/10.123/4567.890). ') ).to eq('10.123/4567.890')
      expect( Id::Doi.extract('doi.org/10.123/4567.890" ') ).to eq('10.123/4567.890')
    end

  end

  describe '#extract_list' do

    it "should extract a list of DOIs" do
      expect( Id::Doi.extract_list("10.1/1.23") ).to eq([ '10.1/1.23' ])
    end

    it "should separate on whitespace" do
      expect( Id::Doi.extract_list("10.1/1.01 10.1/1.02\t10.1/1.03\n10.1/1.04") ).to eq([ '10.1/1.01', '10.1/1.02', '10.1/1.03', '10.1/1.04' ])
    end

    it "should ignore stuff that doesn't look like a DOI" do
      expect( Id::Doi.extract_list("10.1/1.01 -----\n10 sometext\n10.1/1.04") ).to eq([ '10.1/1.01', '10.1/1.04' ])
    end

    it "should remove white space, quotes and punctuation" do
      expect( Id::Doi.extract_list('  "10.1/1.01",  --10.1/1.03  ') ).to eq([ '10.1/1.01', '10.1/1.03' ])
    end

  end

  describe '#prefix' do

    it "should extract a list of DOIs" do
      expect( Id::Doi.prefix("10.1234.5678/abcd.efgfh") ).to eq('10.1234.5678')
    end

  end

  describe '#prefix' do

    it "should get the doi prefix" do
      expect( Id::Doi.prefix("10.1234.5678/abcd.efgfh") ).to eq('10.1234.5678')
    end

    it "should return nil for a nil or empty input" do
      expect( Id::Doi.prefix(nil) ).to be_nil
      expect( Id::Doi.prefix("") ).to be_nil
      expect( Id::Doi.prefix("  ") ).to be_nil
    end

  end

  describe '#is_plos_doi?' do

    it "should return true for a Plos DOI" do
      expect( Id::Doi.is_plos_doi?("10.1371/abcd.efgfh") ).to eq(true)
    end

    it "should return false for a non-Plos DOI" do
      expect( Id::Doi.is_plos_doi?("10.13712/abcd.efgfh") ).to eq(false)
    end

    it "should return false for a nil or empty input" do
      expect( Id::Doi.is_plos_doi?('') ).to eq(false)
    end

  end

end
