require 'spec_helper'

describe Id::Base do
  subject { Id::Base }

  describe '#match_regexes' do

    it "should find a match" do
      match = Id::Base.match_regexes('12345abcdefg890',
                                            [ /(?<result>[a-z]+)/ ] )
      expect(match).to eq('abcdefg')
    end

    it "should return nil if there is no match" do
      match = Id::Base.match_regexes('12345abcdefg890',
                                            [ /foo/, /bar/ ] )
      expect(match).to be_nil
    end

    it "should find multiple matches" do
      match = Id::Base.match_regexes('12345abcdefg890',
                                            [ /(?<result>[a-z]{2})/,
                                              /(?<result>[a-z]+)/    ] )
      expect(match).to eq('ab')
    end

    it "should find the first valid match" do
      match = Id::Base.match_regexes('12345abcdefg890',
                                             [ /(?<result>[a-z]+)/,
                                               /(?<result>[a-z]{2})/    ] )
      expect(match).to eq('abcdefg')
    end

  end

end
