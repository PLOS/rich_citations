require 'spec_helper'

describe Id::Isbn do
  
  describe '#extract' do

    it "should match a 10-digit ISBN string" do
      expect( Id::Isbn.extract('ISBN:1234567890') ).to eq('1234567890')
      expect( Id::Isbn.extract('isbn:1234567890') ).to eq('1234567890')
    end

    it "should match a 13-digit ISBN string" do
      expect( Id::Isbn.extract('isbn:1234567890123') ).to eq('1234567890123')
      expect( Id::Isbn.extract('ISBN:1234567890123') ).to eq('1234567890123')
    end

    it "should handle ISBN's with an X checksum" do
      expect( Id::Isbn.extract('isbn:123456789X') ).to eq('123456789X')
      expect( Id::Isbn.extract('ISBN:123456789012X') ).to eq('123456789012X')
      expect( Id::Isbn.extract('ISBN:123456789012x') ).to eq('123456789012X')
    end

    it "should handle ISBN's with hyphens" do
      expect( Id::Isbn.extract('isbn:123-456-789-0') ).to eq('1234567890')
      expect( Id::Isbn.extract('ISBN: 123-4-56789-012-3') ).to eq('1234567890123')
    end

    it "should handle extra whitespace" do
      expect( Id::Isbn.extract(' isbn: 1234567890 ') ).to eq('1234567890')
    end

    it "should not match ISBN's with invalid lengths" do
      expect( Id::Isbn.extract('isbn:12345678901234') ).to be_nil
      expect( Id::Isbn.extract('isbn:123456789012') ).to be_nil
      expect( Id::Isbn.extract('isbn:123456-789012') ).to be_nil
      expect( Id::Isbn.extract('isbn:123456789') ).to be_nil
      expect( Id::Isbn.extract('isbn:12345678-9') ).to be_nil
    end

    it "should trim trailing punctuation" do
      expect( Id::Isbn.extract('isbn:1234567890. ') ).to eq('1234567890')
    end

  end

end
