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
