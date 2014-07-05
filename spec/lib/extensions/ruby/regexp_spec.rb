require 'spec_helper'

describe Regexp do

  describe "#all_matches" do

    it "should return all the matches" do
      matches = /\s+/.all_matches(' the  end ')
      expect(matches.count).to eq(3)
      expect( matches[0].begin(0) ).to eq(0)
      expect( matches[1].begin(0) ).to eq(4)
      expect( matches[2].begin(0) ).to eq(9)
    end

    it "should return nil if no matches are found" do
      matches = /\s+/.all_matches('-the--end-')
      expect(matches).to be_nil
    end

  end

end
