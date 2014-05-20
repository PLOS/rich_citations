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

  describe "#word_truncate" do

    it "should truncate" do
      expect('Hello Big World!'.word_truncate(1)).to eq('Hello...')
      expect('Hello Big World!'.word_truncate(2)).to eq('Hello Big...')
    end

    it "should not truncate if there are fewer words than requested" do
      expect('Hello Big World!'.word_truncate(3)).to eq('Hello Big World!')
      expect('Hello Big World!'.word_truncate(4)).to eq('Hello Big World!')
    end

    it "should not truncate if there is trailing whitespace" do
      expect('Hello Big World! '.word_truncate(3)).to eq('Hello Big World!')
      expect('Hello Big World! '.word_truncate(4)).to eq('Hello Big World!')
    end

    it "should not count beginning whitespace" do
      expect('  Hello Big World!'.word_truncate(2)).to eq('  Hello Big...')
      expect('  Hello Big World!'.word_truncate(3)).to eq('  Hello Big World!')
    end

    it "should accept an omission string" do
      expect('Hello Big World!'.word_truncate(2, '[...]')).to eq('Hello Big[...]')
    end

  end

  describe "#word_truncate_beginning" do

    it "should truncate" do
      expect('Hello Big World!'.word_truncate_beginning(1)).to eq('...World!')
      expect('Hello Big World!'.word_truncate_beginning(2)).to eq('...Big World!')
    end

    it "should not truncate if there are fewer words than requested" do
      expect('Hello Big World!'.word_truncate_beginning(3)).to eq('Hello Big World!')
      expect('Hello Big World!'.word_truncate_beginning(4)).to eq('Hello Big World!')
    end

    it "should not truncate if there is beginning whitespace" do
      expect(' Hello Big World!'.word_truncate_beginning(3)).to eq('Hello Big World!')
      expect(' Hello Big World!'.word_truncate_beginning(4)).to eq('Hello Big World!')
    end

    it "should not count ending whitespace" do
      expect('Hello Big World!  '.word_truncate_beginning(2)).to eq('...Big World!  ')
      expect('Hello Big World!  '.word_truncate_beginning(3)).to eq('Hello Big World!  ')
    end

    it "should accept an omission string" do
      expect('Hello Big World!'.word_truncate_beginning(2, '[...]')).to eq('[...]Big World!')
    end

  end

end
