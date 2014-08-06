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

describe PaperParser do
  include Spec::XmlBuilder

  describe "::is_failure?" do

    it "should consider nil to be a failure" do
      expect( PaperParser.is_failure?(nil) ).to be_truthy
    end

    it "should return a failure if no XML is provided" do
      result = PaperParser.parse_xml(nil)
      expect( PaperParser.is_failure?(result) ).to be_truthy
    end

    it "should normally return false" do
      xml = Nokogiri::XML('<root/>')
      result = PaperParser.parse_xml(xml)
      expect( PaperParser.is_failure?(result) ).to be_falsy
    end

  end

  describe "#parse" do

    def klass(i)
      o = double("processor #{i}", process:nil, cleanup:nil)
      k = double("processor_klass #{i}", new:o, object:o, dependencies:nil, priority:50, name:"processor_klass #{i}")
    end

    before do
      @klasses = 4.times.map { |i| klass(i+1) }
      @parser = PaperParser.new(:some_xml)
      allow(PaperParser).to receive(:processor_classes).and_return(@klasses)
    end

    it "should instantiate each class" do
      @klasses.each { |k| expect(k).to receive(:new).and_return(k.object) }
      @parser.parse
    end

    it "should process each class" do
      @klasses.each { |k| expect(k.object).to receive(:process).ordered }
      @parser.parse
    end

    it "should cleanup each class after processing" do
      @klasses.each { |k| expect(k.object).to receive(:process).ordered }
      @klasses.each { |k| expect(k.object).to receive(:cleanup).ordered }
      @parser.parse
    end

    it "should include dependencies even if they are not specified" do
      klass = @klasses.first
      allow(klass).to receive(:dependencies).and_return( [@klasses.second, @klasses.third] )
      allow(PaperParser).to receive(:processor_classes).and_return([klass])

      expect(@klasses.second.object).to receive(:process).ordered
      expect(@klasses.third.object).to receive(:process).ordered
      expect(klass.object).to receive(:process).ordered
      @parser.parse
    end

    it "should order dependencies as specified" do
      allow(@klasses.first).to receive(:dependencies).and_return( [@klasses.second, @klasses.third] )

      expect(@klasses.second.object).to receive(:process).ordered
      expect(@klasses.third.object).to receive(:process).ordered
      expect(@klasses.first.object).to receive(:process).ordered
      expect(@klasses.fourth.object).to receive(:process).ordered
      @parser.parse
    end

    it "should order dependencies by priority" do
      allow(@klasses.first).to receive(:priority).and_return(100)
      allow(@klasses.third).to receive(:priority).and_return(0)

      expect(@klasses.third.object).to receive(:process).ordered
      expect(@klasses.second.object).to receive(:process).ordered
      expect(@klasses.fourth.object).to receive(:process).ordered
      expect(@klasses.first.object).to receive(:process).ordered
      @parser.parse
    end

    it "should combine dependencies and priorities" do
      allow(@klasses.first).to receive(:priority).and_return(100)
      allow(@klasses.third).to receive(:priority).and_return(0)
      allow(@klasses.third).to receive(:dependencies).and_return( @klasses.second )

      expect(@klasses.second.object).to receive(:process).ordered
      expect(@klasses.third.object).to receive(:process).ordered
      expect(@klasses.fourth.object).to receive(:process).ordered
      expect(@klasses.first.object).to receive(:process).ordered
      @parser.parse
    end

    it "should load processors from the file system" do
      allow(PaperParser).to receive(:processor_classes).and_call_original
      expect(PaperParser.processor_classes).to include(Processors::References)
    end

    it "should load each processor class in order" do
      allow(PaperParser).to receive(:processor_classes).and_call_original
      expect(PaperParser.resolved_processor_classes).to eq([
                                                             Processors::State,
                                                             Processors::References,
                                                             Processors::ReferencesIdentifier,
                                                             Processors::ReferencesInfoCacheLoader,
                                                             Processors::ReferencesLicense,
                                                             Processors::Authors,
                                                             Processors::CitationGroups,
                                                             Processors::CitationGroupContext,
                                                             Processors::CitationGroupPosition,
                                                             Processors::CitationGroupSection,
                                                             Processors::Doi,
                                                             Processors::ReferencesInfoFromDoi,
                                                             Processors::ReferencesInfoFromIsbn,
                                                             Processors::ReferencesInfoFromPubmed,
                                                             Processors::ReferencesInfoFromPmc,
                                                             Processors::ReferencesInfoFromArxiv,
                                                             Processors::ReferencesInfoFromGithub,
                                                             Processors::ReferencesInfoFromCitationNode,
                                                             Processors::ReferencesInfoFromCitationText,
                                                             Processors::NormalizeAuthorNames,
                                                             Processors::PaperInfo,
                                                             Processors::ReferencesAbstract,
                                                             Processors::ReferencesCitedGroups,
                                                             Processors::ReferencesCrossmark,
                                                             Processors::ReferencesMedianCoCitations,
                                                             Processors::ReferencesMentionCount,
                                                             Processors::ReferencesSection,
                                                             Processors::ReferencesZeroMentions,
                                                             Processors::SelfCitations,
                                                             Processors::ReferencesDelayedLicense,
                                                             Processors::ReferencesInfoCacheSaver,
                                                           ])

    end

  end

end
