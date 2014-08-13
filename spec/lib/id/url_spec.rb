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

describe Id::Url do

  def xml(text)
    Nokogiri::XML(text)
  end

  describe '#extract' do

    it "should return nil if no url is found" do
      expect( Id::Url.extract('proto://plos.org/url') ).to be_nil
    end

    it "should extract a url" do
      expect( Id::Url.extract('http://plos.org/url') ).to eq('http://plos.org/url')
      expect( Id::Url.extract('https://plos.org/url') ).to eq('https://plos.org/url')
    end

    it "should handle extra whitespace" do
      expect( Id::Url.extract('  http://plos.org/url  ') ).to eq('http://plos.org/url')
    end

    it "should trim trailing punctuation" do
      expect( Id::Url.extract('http://plos.org/url.') ).to eq('http://plos.org/url')
    end

  end

  describe '#extract_from_xml' do

    context "extracting a link" do

      it "should return nil of no link is found" do

        fragment = xml(<<-XML)
          <ref id="pone.0038649-GitHub1">
            <element-citation publication-type="journal" xlink:type="simple">
              <article-title>GitHub website.</article-title>
              <volume>15</volume>
              <comment>Available: <ext-link ext-link-type="uri" xlink:href="proto://github.com/samuellab/EarlyVersionWormTracker" xlink:type="simple">proto://github.com/not-this-url</ext-link> Stuff</comment>
            </element-citation>
          </ref>
        XML

        expect( Id::Url.extract_from_xml(fragment) ).to be_nil
      end

      it "should extract a link from an ext-link attribute" do

        fragment = xml(<<-XML)
          <ref id="pone.0038649-GitHub1">
            <element-citation publication-type="journal" xlink:type="simple">
              <article-title>GitHub website.</article-title>
              <volume>15</volume>
              <comment>Available: <ext-link ext-link-type="uri" xlink:href="https://github.com/samuellab/EarlyVersionWormTracker" xlink:type="simple">https://github.com/not-this-url</ext-link> Stuff</comment>
            </element-citation>
          </ref>
        XML

        expect( Id::Url.extract_from_xml(fragment) ).to eq(url:"https://github.com/samuellab/EarlyVersionWormTracker")
      end

      it "should extract a link from an <a> attribute" do

        fragment = xml(<<-XML)
          <ref id="pone.0038649-GitHub1">
            <element-citation publication-type="journal" xlink:type="simple">
              <article-title>GitHub website.</article-title>
              <volume>15</volume>
              <comment>Available: <a href="https://github.com/samuellab/EarlyVersionWormTracker">https://github.com/not-this-url</a> Accessed Stuff</comment>
            </element-citation>
          </ref>
        XML

        expect( Id::Url.extract_from_xml(fragment) ).to eq(url:"https://github.com/samuellab/EarlyVersionWormTracker")
      end

      it "should extract a link from the text" do

        fragment = xml(<<-XML)
          <ref id="pone.0038649-GitHub1">
            <element-citation publication-type="journal" xlink:type="simple">
              <article-title>GitHub website.</article-title>
              <volume>15</volume>
              <comment>Available: <b>  https://github.com/samuellab/EarlyVersionWormTracker </b> Stuff</comment>
            </element-citation>
          </ref>
        XML

        expect( Id::Url.extract_from_xml(fragment) ).to eq(url:"https://github.com/samuellab/EarlyVersionWormTracker")
      end

    end

    context "extracting the last access date" do

      it "should extract an accessed date from an ext-link attribute" do

        fragment = xml(<<-XML)
          <ref id="pone.0038649-GitHub1">
            <element-citation publication-type="journal" xlink:type="simple">
              <article-title>GitHub website.</article-title>
              <volume>15</volume>
              <comment>Available: <ext-link ext-link-type="uri" xlink:href="https://github.com/samuellab/EarlyVersionWormTracker" xlink:type="simple">https://github.com/not-this-url</ext-link> Accessed 2012 May 7</comment>
            </element-citation>
          </ref>
        XML

        expect( Id::Url.extract_from_xml(fragment) ).to eq(url:"https://github.com/samuellab/EarlyVersionWormTracker", accessed:Date.new(2012,5,7) )
      end

      it "should extract a link from an <a> attribute" do

        fragment = xml(<<-XML)
          <ref id="pone.0038649-GitHub1">
            <element-citation publication-type="journal" xlink:type="simple">
              <article-title>GitHub website.</article-title>
              <volume>15</volume>
              <comment>Available: <a href="https://github.com/samuellab/EarlyVersionWormTracker">https://github.com/not-this-url</a> Accessed 2012 May 7</comment>
            </element-citation>
          </ref>
        XML

        expect( Id::Url.extract_from_xml(fragment) ).to eq(url:"https://github.com/samuellab/EarlyVersionWormTracker", accessed:Date.new(2012,5,7) )
      end

      it "should extract a link from the text" do

        fragment = xml(<<-XML)
          <ref id="pone.0038649-GitHub1">
            <element-citation publication-type="journal" xlink:type="simple">
              <article-title>GitHub website.</article-title>
              <volume>15</volume>
              <comment>Available: <b>  https://github.com/samuellab/EarlyVersionWormTracker </b> Accessed 2012 May 7</comment>
            </element-citation>
          </ref>
        XML

        expect( Id::Url.extract_from_xml(fragment) ).to eq(url:"https://github.com/samuellab/EarlyVersionWormTracker", accessed:Date.new(2012,5,7) )
      end

      it "should ignore extraneous punctuation" do

        fragment = xml(<<-XML)
          <ref id="pone.0038649-GitHub1">
            <ext-link xlink:href="https://github.com/samuellab/EarlyVersionWormTracker">https://github.com/not-this-url</ext-link> .! Accessed 2012 May 7.!
          </ref>
        XML

        expect( Id::Url.extract_from_xml(fragment)[:accessed] ).to eq( Date.new(2012,5,7) )
      end

      it "should ignore an 'accessed' keyword" do

        fragment = xml(<<-XML)
          <ref id="pone.0038649-GitHub1">
            <ext-link xlink:href="https://github.com/samuellab/EarlyVersionWormTracker">https://github.com/not-this-url</ext-link>  Accessed: 2012 May 7
          </ref>
        XML

        expect( Id::Url.extract_from_xml(fragment)[:accessed] ).to eq( Date.new(2012,5,7) )
      end

      it "should ignore a 'retrieved' keyword" do

        fragment = xml(<<-XML)
          <ref id="pone.0038649-GitHub1">
            <ext-link xlink:href="https://github.com/samuellab/EarlyVersionWormTracker">https://github.com/not-this-url</ext-link>  retrieved: 2012 May 7
          </ref>
        XML

        expect( Id::Url.extract_from_xml(fragment)[:accessed] ).to eq( Date.new(2012,5,7) )
      end

      it "should be ok if there is no keyword" do

        fragment = xml(<<-XML)
          <ref id="pone.0038649-GitHub1">
            <ext-link xlink:href="https://github.com/samuellab/EarlyVersionWormTracker">https://github.com/not-this-url</ext-link>2012 May 7
          </ref>
        XML

        expect( Id::Url.extract_from_xml(fragment)[:accessed] ).to eq( Date.new(2012,5,7) )
      end

      it "should parse a date like '2012 December 7' " do

        fragment = xml(<<-XML)
          <ref id="pone.0038649-GitHub1">
            <ext-link xlink:href="https://github.com/samuellab/EarlyVersionWormTracker">https://github.com/not-this-url</ext-link>2012 December 7
          </ref>
        XML

        expect( Id::Url.extract_from_xml(fragment)[:accessed] ).to eq( Date.new(2012,12,7) )
      end

      it "should parse a date like 'December 7, 2012' " do

        fragment = xml(<<-XML)
          <ref id="pone.0038649-GitHub1">
            <ext-link xlink:href="https://github.com/samuellab/EarlyVersionWormTracker">https://github.com/not-this-url</ext-link>May 7, 2012
          </ref>
        XML

        expect( Id::Url.extract_from_xml(fragment)[:accessed] ).to eq( Date.new(2012,5,7) )
      end

      it "should parse a date like ' Mon, 07 May 2012' " do

        fragment = xml(<<-XML)
          <ref id="pone.0038649-GitHub1">
            <ext-link xlink:href="https://github.com/samuellab/EarlyVersionWormTracker">https://github.com/not-this-url</ext-link> Mon, 07 May 2012
          </ref>
        XML

        expect( Id::Url.extract_from_xml(fragment)[:accessed] ).to eq( Date.new(2012,5,7) )
      end

      it "should parse a date like '2012-12-17' " do

        fragment = xml(<<-XML)
          <ref id="pone.0038649-GitHub1">
            <ext-link xlink:href="https://github.com/samuellab/EarlyVersionWormTracker">https://github.com/not-this-url</ext-link>2012-12-17
        XML

        expect( Id::Url.extract_from_xml(fragment)[:accessed] ).to eq( Date.new(2012,12,17) )
      end

      it "should parse a date like '14-07-2012' " do

        fragment = xml(<<-XML)
          <ref id="pone.0038649-GitHub1">
            <ext-link xlink:href="https://github.com/samuellab/EarlyVersionWormTracker">https://github.com/not-this-url</ext-link>14-07-2012
          </ref>
        XML

        expect( Id::Url.extract_from_xml(fragment)[:accessed] ).to eq( Date.new(2012,7,14) )
      end

      it "should ignore a year only" do

        fragment = xml(<<-XML)
          <ref id="pone.0038649-GitHub1">
            <ext-link xlink:href="https://github.com/samuellab/EarlyVersionWormTracker">https://github.com/not-this-url</ext-link>2012
          </ref>
        XML

        expect( Id::Url.extract_from_xml(fragment)[:accessed] ).to be_nil
      end

    end

  end

end
