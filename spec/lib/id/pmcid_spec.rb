require 'spec_helper'

describe Id::Pmcid do
  
  describe '#extract' do

    it "should match a string starting with pmcid" do
      expect( Id::Pmcid.extract('pmcid:1234567890') ).to eq('PMC1234567890')
      expect( Id::Pmcid.extract('Pmcid: 1234567890') ).to eq('PMC1234567890')
      expect( Id::Pmcid.extract('Pmcid: PMC1234567890') ).to eq('PMC1234567890')
    end

    it "should match a string starting with pubmed commons id" do
      expect( Id::Pmcid.extract('pubmed commons id:1234567890123') ).to eq('PMC1234567890123')
      expect( Id::Pmcid.extract('Pubmed Commons ID: 1234567890123') ).to eq('PMC1234567890123')
      expect( Id::Pmcid.extract('Pubmed Commons ID: pmc1234567890123') ).to eq('PMC1234567890123')
    end

    it "should match a string with no prefix but including PMC before the numbers" do
      expect( Id::Pmcid.extract('PMC1234567890123') ).to eq('PMC1234567890123')
      expect( Id::Pmcid.extract('Stuff.PMC1234567890123') ).to eq('PMC1234567890123')
      expect( Id::Pmcid.extract('1234567890123') ).to be_nil
    end

    it "should handle extra whitespace" do
      expect( Id::Pmcid.extract(' Pmcid: 1234567890 ') ).to eq('PMC1234567890')
    end

    it "should not match Pmcid's with invalid lengths" do
      expect( Id::Pmcid.extract('Pmcid:123456789012345678901') ).to be_nil
      expect( Id::Pmcid.extract('Pmcid:12345678901234567890') ).not_to be_nil
      expect( Id::Pmcid.extract('Pmcid:123') ).to be_nil
      expect( Id::Pmcid.extract('Pmcid:1234') ).not_to be_nil
    end

    it "should trim trailing punctuation" do
      expect( Id::Pmcid.extract('Pmcid:1234567890. ') ).to eq('PMC1234567890')
    end

  end

end
