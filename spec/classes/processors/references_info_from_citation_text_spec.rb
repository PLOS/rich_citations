require 'spec_helper'

describe Processors::ReferencesInfoFromCitationText do
  include Spec::ProcessorHelper

  it "should extract info fields from the reference node" do
    ref_node = Nokogiri::XML.parse <<-XML
        <ref id="pbio.1001675-Mahdi1"><label>3</label>
        <mixed-citation xlink:type="simple">Mahdi S, D'Este P, Neely A (2008) Citation counts: are they good predictors of RAE scores?</mixed-citation>
        </ref>
    XML

    process( references: { 'ref-1' => {
      node: ref_node,
      info: {},
    } } )

    expect(result[:references]['ref-1'][:info]).to eq( title:       'Citation counts: are they good predictors of RAE scores?',
                                                       issued:      {:"date-parts"=>[[2008]]},
                                                       author:      [{literal:"Mahdi S, D'Este P, Neely A"}   ],
                                                       info_source: "RefText"
                                                     )
  end

  it "should extract html with the title" do
    ref_node = Nokogiri::XML.parse <<-XML
        <ref id="pbio.1001675-Mahdi1"><label>3</label>
        <mixed-citation xlink:type="simple">Mahdi S, D'Este P, Neely A (2008) Citation counts: <italic>are they good predictors of RAE scores</italic>?</mixed-citation>
        </ref>
    XML

    process( references: { 'ref-1' => {
        node: ref_node,
        info: {},
    } } )

    expect(result[:references]['ref-1'][:info][:title]).to eq('Citation counts: <italic>are they good predictors of RAE scores</italic>?')
  end

  it "should not overwrite existing fields" do
    ref_node = Nokogiri::XML.parse <<-XML
      <ref id="pbio.1001675-Mahdi1"><label>3</label>
      <mixed-citation xlink:type="simple">Mahdi S, D'Este P, Neely A (2008) Citation counts: are they good predictors of RAE scores? Available: <ext-link ext-link-type="uri" xlink:href="http://dspace.lib.cranfield.ac.uk/handle/1826/2248" xlink:type="simple">http://dspace.lib.cranfield.ac.uk/handle/1826/2248</ext-link></mixed-citation>
      </ref>
    XML

    process( references: { 'ref-1' => {
        node: ref_node,
        info: {
            title: 'Article Title',
            issued: {:"date-parts"=>[[2001,1,1]] },
            author:
                 [{family:"Roberts", given:"J"},
                  {family:"Jolie",   given:"J"} ]

    } } } )

    expect(result[:references]['ref-1'][:info]).to eq( title:   'Article Title',
                                                       issued:  {:"date-parts"=>[[2001,1,1]] },
                                                       author:
                                                           [{family:"Roberts", given:"J"},
                                                            {family:"Jolie",   given:"J"}]                )
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

  it "should not add an info_source attribute if no changes are made" do
    ref_node = Nokogiri::XML.parse <<-XML
      <ref id="pbio.1001675-Mahdi1"><label>3</label>
      <mixed-citation xlink:type="simple">Mahdi S, D'Este P, Neely A (2008) Citation counts</mixed-citation>
      </ref>
    XML

    process( references: { 'ref-1' => {
        node: ref_node,
        info: {
            title: 'Citation counts',
            issued: {:"date-parts"=>[[2001,1,1]] },
            author:
                [{family:"Roberts", given:"J"},
                 {family:"Jolie",   given:"J"} ]

        } } } )

    expect(result[:references]['ref-1'][:info][:info_source]).to be_nil
  end

  it "should not add an info_source attribute if one already exists" do
    ref_node = Nokogiri::XML.parse <<-XML
      <ref id="pbio.1001675-Mahdi1"><label>3</label>
      <mixed-citation xlink:type="simple">Mahdi S, D'Este P, Neely A (2008) Citation counts</mixed-citation>
      </ref>
    XML

    process( references: { 'ref-1' => {
        node: ref_node,
        info: {
            info_source:'OriginalSource'
        } } } )

    expect(result[:references]['ref-1'][:info][:title]).to eq('Citation counts')
    expect(result[:references]['ref-1'][:info][:info_source]).to eq('OriginalSource')
  end

end
