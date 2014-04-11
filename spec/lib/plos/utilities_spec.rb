require 'spec_helper'

describe Plos::Utilities do
  subject { Plos::Utilities }

  describe '#match' do

    it "should find a match" do
      match = Plos::Utilities.match('12345abcdefg890',
                                    [ /(?<result>[a-z]+)/ ] )
      expect(match).to eq('abcdefg')
    end

    it "should return nil if there is no match" do
      match = Plos::Utilities.match('12345abcdefg890',
                                    [ /foo/, /bar/ ] )
      expect(match).to be_nil
    end

    it "should find multiple matches" do
      match = Plos::Utilities.match('12345abcdefg890',
                                    [ /(?<result>[a-z]{2})/,
                                      /(?<result>[a-z]+)/    ] )
      expect(match).to eq('ab')
    end

    it "should find the first valid match" do
      match = Plos::Utilities.match('12345abcdefg890',
                                    [ /(?<result>[a-z]+)/,
                                      /(?<result>[a-z]{2})/    ] )
      expect(match).to eq('abcdefg')
    end

  end

  describe '#extract_doi' do

    it "should match a doi string" do
      expect( subject.extract_doi('doi:10.123/4567.890 ') ).to eq('10.123/4567.890')
      expect( subject.extract_doi('doi 10.123/4567.890 ') ).to eq('10.123/4567.890')
      expect( subject.extract_doi('dOi 10.123/4567.890 ') ).to eq('10.123/4567.890')
      expect( subject.extract_doi('DOI: 10.123/4567.890') ).to eq('10.123/4567.890')
      expect( subject.extract_doi(' doi:10.123/4567.890') ).to eq('10.123/4567.890')
    end

    it "should not match some similar strings" do
      expect( subject.extract_doi('xdoi:10.123/4567.890 ') ).to be_nil
      expect( subject.extract_doi('doi:11.123/4567.890 ') ).to be_nil
    end

    it "should trim trailing punctuation" do
      expect( subject.extract_doi('doi:10.123/4567.890. ') ).to eq('10.123/4567.890')
      expect( subject.extract_doi('doi:10.123/4567.890.') ).to eq('10.123/4567.890')
      expect( subject.extract_doi('doi:10.123/4567.890). ') ).to eq('10.123/4567.890')
      expect( subject.extract_doi('doi:10.123/4567.890" ') ).to eq('10.123/4567.890')
    end

    it "should match a doi url" do
      expect( subject.extract_doi('doi.org/10.123/4567.890 ') ).to eq('10.123/4567.890')
      expect( subject.extract_doi('dx.doi.org/10.123/4567.890 ') ).to eq('10.123/4567.890')
      expect( subject.extract_doi('dOi.ORG/10.123/4567.890') ).to eq('10.123/4567.890')
    end

    it "should unescape a DOI url" do
      expect( subject.extract_doi('doi.org/10.123/4+5%3D6%267%208. ') ).to eq('10.123/4 5=6&7 8')
    end

    it "prefers the URL doi to the inline DOI" do
      expect( subject.extract_doi('doi.org/10.123/4567.890 doi:10.123/9765.432 ') ).to eq('10.123/4567.890')
    end

    it "should not match some similar doi URLs" do
      expect( subject.extract_doi('xdoi.org/10.123/4567.890 ') ).to be_nil
      expect( subject.extract_doi('doi.org:10.123/4567.890 ') ).to be_nil
      expect( subject.extract_doi('doi.org/11.123/4567.890 ') ).to be_nil
    end

    it "should trim trailing punctuation in urls" do
      expect( subject.extract_doi('doi.org/10.123/4567.890. ') ).to eq('10.123/4567.890')
      expect( subject.extract_doi('doi.org/10.123/4567.890.') ).to eq('10.123/4567.890')
      expect( subject.extract_doi('doi.org/10.123/4567.890). ') ).to eq('10.123/4567.890')
      expect( subject.extract_doi('doi.org/10.123/4567.890" ') ).to eq('10.123/4567.890')
    end

  end

end
