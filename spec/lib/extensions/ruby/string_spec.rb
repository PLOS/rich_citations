require 'spec_helper'

describe String do

  describe "#word_count" do

    it "should return the word count" do
      expect( "one two three".word_count ).to be(3)
    end

    it "should ignore multiple whitepsace" do
      expect( "one  \ntwo \t three".word_count ).to be(3)
    end

    it "should ignore starting and ending whitepsace" do
      expect( "\n\t one  two  three\n\t ".word_count ).to be(3)
    end

  end

  # Extracted from Rails ActiveSupport
  describe "#truncate_beginning" do

    it "should truncate" do
      expect('Hello World!'.truncate_beginning(12)).to eq("Hello World!")
      expect('!Hello World!'.truncate_beginning(12)).to eq("...lo World!")
    end

    it "should truncate with omission and separator" do
      expect( 'Hello World!'.truncate_beginning(10, omission: "[...]") ).to eq('[...]orld!')
      expect( 'Hello Big World!'.truncate_beginning(13, omission: "[...]", :separator => ' ') ).to eq('[...]World!')
      expect( 'Hello Big World!'.truncate_beginning(14, omission: "[...]", :separator => ' ') ).to eq('[...]World!')
      expect( 'Hello Big World!'.truncate_beginning(15, omission: "[...]", :separator => ' ') ).to eq('[...]World!')
    end

    it "should truncate with non-whitespace" do
      expect( 'Hello Big-World!'.truncate_beginning(15, omission: "[...]", :separator => '-') ).to eq('[...]World!')
    end

    it "truncate with omission and regexp separator" do
      expect( 'Hello Big World!'.truncate_beginning(13, omission: "[...]",  :separator => /\s/) ).to eq('[...]World!')
      expect( 'Hello Big World!'.truncate_beginning(14, omission: "[...]",  :separator => /\s/) ).to eq('[...]World!')
      expect( 'Hello Big World!'.truncate_beginning(15, omission: "[...]",  :separator => /\s/) ).to eq('[...]World!')
    end

    it "truncate with multiple whitespaces" do
      expect( 'Hello  Big  World!'.truncate_beginning(13, omission: "[...]",  :separator => /\s+/) ).to eq('[...]World!')
      expect( 'Hello  Big  World!'.truncate_beginning(13, omission: "[...]",  :separator => /\s/) ).to eq('[...]World!')
    end

  end

end
