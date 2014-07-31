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

  describe "#word_truncate_ending" do

    it "should truncate" do
      expect('Hello Big World!'.word_truncate_ending(1)).to eq(['Hello',     true ])
      expect('Hello Big World!'.word_truncate_ending(2)).to eq(['Hello Big', true ])
    end

    it "should not truncate if there are fewer words than requested" do
      expect('Hello Big World!'.word_truncate_ending(3)).to eq(['Hello Big World!', false ])
      expect('Hello Big World!'.word_truncate_ending(4)).to eq(['Hello Big World!', false ])
    end

    it "should not truncate if there is trailing whitespace" do
      expect('Hello Big World! '.word_truncate_ending(3)).to eq(['Hello Big World!', false ])
      expect('Hello Big World! '.word_truncate_ending(4)).to eq(['Hello Big World!', false ])
    end

    it "should not count beginning whitespace" do
      expect('  Hello Big World!'.word_truncate_ending(2)).to eq(['  Hello Big',        true  ])
      expect('  Hello Big World!'.word_truncate_ending(3)).to eq(['  Hello Big World!', false ])
    end

  end

  describe "#word_truncate_beginning" do

    it "should truncate" do
      expect('Hello Big World!'.word_truncate_beginning(1)).to eq([ 'World!',     true ])
      expect('Hello Big World!'.word_truncate_beginning(2)).to eq([ 'Big World!', true ])
    end

    it "should not truncate if there are fewer words than requested" do
      expect('Hello Big World!'.word_truncate_beginning(3)).to eq([ 'Hello Big World!', false ])
      expect('Hello Big World!'.word_truncate_beginning(4)).to eq([ 'Hello Big World!', false ])
    end

    it "should not truncate if there is beginning whitespace" do
      expect(' Hello Big World!'.word_truncate_beginning(3)).to eq([ 'Hello Big World!', false ])
      expect(' Hello Big World!'.word_truncate_beginning(4)).to eq([ 'Hello Big World!', false ])
    end

    it "should not count ending whitespace" do
      expect('Hello Big World!  '.word_truncate_beginning(2)).to eq([ 'Big World!  ',       true  ])
      expect('Hello Big World!  '.word_truncate_beginning(3)).to eq([ 'Hello Big World!  ', false ])
    end

  end

end
