# coding: utf-8
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

# coding: utf-8
require 'spec_helper'

describe Processors::ReferencesInfoFromCitationNode do
  include Spec::ProcessorHelper

  it "should extract info fields from the reference node" do
    ref_node = Nokogiri::XML.parse <<-XML
      <ref id="pbio.1001675-Davenport1"><label>17</label>
        <mixed-citation publication-type="journal" xlink:type="simple">
          <name name-style="western"><surname>Davenport</surname><given-names>E</given-names></name>,
          <name name-style="western"><surname>Snyder</surname><given-names>H</given-names></name>
          (<year>1995</year>)
          <article-title>Who cites women? Whom do women cite? An exploration of gender and scholarly citation in sociology</article-title>.
          <source>J Doc</source> <volume>51</volume>: <fpage>404</fpage>–<lpage>410</lpage>.
        </mixed-citation>
      </ref>
    XML

    process( references: { 'ref-1' => {
      node: ref_node,
      info: {},
    } } )

    expect(result[:references]['ref-1'][:info]).to eq( :"container-type" => "journal",
                                                       :"container-title"=> "J Doc",
                                                       :title            => 'Who cites women? Whom do women cite? An exploration of gender and scholarly citation in sociology',
                                                       :volume           => "51",
                                                       :issued           => {:"date-parts"=>[[1995]]},
                                                       :page             =>"404-410",
                                                       :author           =>
                                                           [{:family=>"Davenport", :given=>"E"},
                                                            {:family=>"Snyder",    :given=>"H"}],
                                                       :info_source      => 'RefNode'
                                                      )
  end

  it "should extract html formatting with the title" do
    ref_node = Nokogiri::XML.parse <<-XML
      <ref id="pbio.1001675-Davenport1"><label>17</label>
        <mixed-citation publication-type="journal" xlink:type="simple">
          <article-title>Who cites <italic>women</italic>?</article-title>.
        </mixed-citation>
      </ref>
    XML

    process( references: { 'ref-1' => {
        node: ref_node,
        info: {},
    } } )

    expect(result[:references]['ref-1'][:info][:title]).to eq('Who cites <i>women</i>?')
  end

  it "should extract only a start page" do
    ref_node = Nokogiri::XML.parse <<-XML
      <ref id="pbio.1001675-Davenport1"><label>17</label>
        <mixed-citation publication-type="journal" xlink:type="simple">
          <fpage>404</fpage>.
        </mixed-citation>
      </ref>
    XML

    process( references: { 'ref-1' => {
        node: ref_node,
        info: {},
    } } )

    expect(result[:references]['ref-1'][:info][:page]).to eq('404-404')
  end

  it "should extract a start and end page" do
    ref_node = Nokogiri::XML.parse <<-XML
      <ref id="pbio.1001675-Davenport1"><label>17</label>
        <mixed-citation publication-type="journal" xlink:type="simple">
          <fpage>404</fpage>-<lpage>410</lpage>.
        </mixed-citation>
      </ref>
    XML

    process( references: { 'ref-1' => {
        node: ref_node,
        info: {},
    } } )

    expect(result[:references]['ref-1'][:info][:page]).to eq('404-410')
  end

  it "should not overwrite existing fields" do
    ref_node = Nokogiri::XML.parse <<-XML
      <ref id="pbio.1001675-Davenport1"><label>17</label>
        <mixed-citation publication-type="journal" xlink:type="simple">
          <name name-style="western"><surname>Davenport</surname><given-names>E</given-names></name>,
          <name name-style="western"><surname>Snyder</surname><given-names>H</given-names></name>
          (<year>1995</year>)
          <article-title>Who cites women? Whom do women cite? An exploration of gender and scholarly citation in sociology</article-title>.
          <source>J Doc</source> <volume>51</volume>: <fpage>404</fpage>–<lpage>410</lpage>.
        </mixed-citation>
      </ref>
    XML

    process( references: { 'ref-1' => {
        node: ref_node,
        info: {
            :"container-type" => "paper",
            :"container-title"=> "Container Title",
            :title            => 'Article Title',
            :volume           => "99",
            :issued           => {:"date-parts"=>[[2001,1,1]] },
            :page             =>"100-101",
            :author           =>
                 [{:family=>"Roberts", :given=>"J"},
                  {:family=>"Jolie",   :given=>"J"} ]

    } } } )

    expect(result[:references]['ref-1'][:info]).to eq( :"container-type" => "paper",
                                                       :"container-title"=> "Container Title",
                                                       :title            => 'Article Title',
                                                       :volume           => "99",
                                                       :issued           => {:"date-parts"=>[[2001,1,1]] },
                                                       :page             =>"100-101",
                                                       :author           =>
                                                           [{:family=>"Roberts", :given=>"J"},
                                                            {:family=>"Jolie",   :given=>"J"}]                )
  end

  it "should not add null info fields" do
    ref_node = Nokogiri::XML.parse <<-XML
      <ref id="pbio.1001675-Davenport1"><label>17</label>
        <mixed-citation xlink:type="simple">
        </mixed-citation>
      </ref>
    XML

    process( references: { 'ref-1' => {
        node: ref_node,
        info: {},
    } } )

    expect(result[:references]['ref-1'][:info]).to eq( { } )
  end

  it "should not add an info_source if no changes are made" do
    ref_node = Nokogiri::XML.parse <<-XML
      <ref id="pbio.1001675-Davenport1"><label>17</label>
        <mixed-citation publication-type="" xlink:type="simple">
          <source></source>
          <volume></volume>
          (<year>1995</year>)
          <article-title>Who cites women? Whom do women cite? An exploration of gender and scholarly citation in sociology</article-title>.
        </mixed-citation>
      </ref>
    XML

    process( references: { 'ref-1' => {
        node: ref_node,
        info: {
            :"container-type" => "paper",
            :"container-title"=> "Container Title",
            :title            => 'Article Title',
            :volume           => "99",
            :issued           => {:"date-parts"=>[[2001,1,1]] },
            :page             =>"100-101",
            :author           =>
                [{:family=>"Roberts", :given=>"J"},
                 {:family=>"Jolie",   :given=>"J"} ]
        } } } )

    expect(result[:references]['ref-1'][:info][:info_source]).to be_nil
  end

  it "should not add an info_source if one already exists" do
    ref_node = Nokogiri::XML.parse <<-XML
      <ref id="pbio.1001675-Davenport1"><label>17</label>
        <mixed-citation publication-type="" xlink:type="simple">
          <article-title>New Title.</article-title>.
        </mixed-citation>
      </ref>
    XML

    process( references: { 'ref-1' => {
        node: ref_node,
        info: {
            :info_source      => 'OriginalSource',
        } } } )

    expect(result[:references]['ref-1'][:info][:info_source]).to eq('OriginalSource')
  end

end
