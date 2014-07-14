require 'spec_helper'

describe Id::Pmid do
  
  describe '#extract' do

    it "should match a string starting with pmid" do
      expect( Id::Pmid.extract('pmid:1234567890') ).to eq('1234567890')
      expect( Id::Pmid.extract('Pmid: 1234567890') ).to eq('1234567890')
    end

    it "should match a string starting with pubmed" do
      expect( Id::Pmid.extract('pubmed:1234567890123') ).to eq('1234567890123')
      expect( Id::Pmid.extract('Pubmed: 1234567890123') ).to eq('1234567890123')
    end

    it "should match a string starting with pubmedid" do
      expect( Id::Pmid.extract('pubmedid:1234567890123') ).to eq('1234567890123')
      expect( Id::Pmid.extract('Pubmedid: 1234567890123') ).to eq('1234567890123')
    end

    it "should match a string starting with pubmed id" do
      expect( Id::Pmid.extract('pubmed id:1234567890123') ).to eq('1234567890123')
      expect( Id::Pmid.extract('Pubmed ID: 1234567890123') ).to eq('1234567890123')
    end

    it "should handle extra whitespace" do
      expect( Id::Pmid.extract(' Pmid: 1234567890 ') ).to eq('1234567890')
    end

    it "should not match Pmid's with invalid lengths" do
      expect( Id::Pmid.extract('Pmid:123456789012345678901') ).to be_nil
      expect( Id::Pmid.extract('Pmid:12345678901234567890') ).not_to be_nil
      expect( Id::Pmid.extract('Pmid:123') ).to be_nil
      expect( Id::Pmid.extract('Pmid:1234') ).not_to be_nil
    end

    it "should trim trailing punctuation" do
      expect( Id::Pmid.extract('Pmid:1234567890. ') ).to eq('1234567890')
    end

  end

end
