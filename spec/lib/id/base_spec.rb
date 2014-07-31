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
