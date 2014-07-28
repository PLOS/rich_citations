require 'spec_helper'

describe Processors::ReferencesInfoFromPmc do
  include Spec::ProcessorHelper

  it "should call the API" do
    refs 'First', 'Second', 'Third'
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :pmcid, id:'PMC1111111111' },
                                                              'ref-2' => { },
                                                              'ref-3' => { id_type: :pmcid, id:'PMC2222222222' })

    expect(HttpUtilities).to receive(:post).with('http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pmc&retmode=xml',
                                                 'id=PMC1111111111,PMC2222222222',
                                                 'Accept'       => Mime::XML,
                                                 'Content-Type' => Mime::URL_ENCODED_FORM).and_return('{}')

    process
  end

  before do
    refs 'First'
  end

  def ref_info
    result[:references]['ref-1'][:info]
  end

  def test_response(pmcid='1111111111', xml='')
    <<-XML
    <pmc-articleset>
    <article xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:mml="http://www.w3.org/1998/Math/MathML" article-type="research-article">
      <front>
        <article-meta>
          <article-id pub-id-type="pmc">#{pmcid}</article-id>
          #{xml}
        </article-meta>
      <front>
    </article>
    </pmc-articleset>
  XML
  end

  sample_response = <<-XML
    <?xml version="1.0"?>
    <!DOCTYPE pmc-articleset PUBLIC "-//NLM//DTD ARTICLE SET 2.0//EN" "http://dtd.nlm.nih.gov/ncbi/pmc/articleset/nlm-articleset-2.0.dtd">
    <pmc-articleset>
    <article xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:mml="http://www.w3.org/1998/Math/MathML" article-type="research-article">
      <!--The publisher of this article does not allow downloading of the full text in XML form.-->
      <front>
        <journal-meta>
          <journal-id journal-id-type="nlm-ta">Proc Natl Acad Sci U S A</journal-id>
          <journal-id journal-id-type="hwp">pnas</journal-id>
          <journal-id journal-id-type="pmc">pnas</journal-id>
          <journal-id journal-id-type="publisher-id">PNAS</journal-id>
          <journal-title-group>
            <journal-title>Proceedings of the National Academy of Sciences of the United States of America</journal-title>
          </journal-title-group>
          <issn pub-type="ppub">0027-8424</issn>
          <issn pub-type="epub">1091-6490</issn>
          <publisher>
            <publisher-name>National Academy of Sciences</publisher-name>
          </publisher>
        </journal-meta>
        <article-meta>
          <article-id pub-id-type="pmid">19246383</article-id>
          <article-id pub-id-type="pmc">2647976</article-id>
          <article-id pub-id-type="publisher-id">7012</article-id>
          <article-id pub-id-type="doi">10.1073/pnas.0812194106</article-id>
          <article-categories>
            <subj-group subj-group-type="heading">
              <subject>Biological Sciences</subject>
              <subj-group>
                <subject>Microbiology</subject>
              </subj-group>
            </subj-group>
          </article-categories>
          <title-group>
            <article-title>Multiple posttranscriptional regulatory mechanisms partner to control ethanolamine utilization</article-title>
          </title-group>
          <contrib-group>
            <contrib contrib-type="author">
              <name>
                <surname>Fox</surname>
                <given-names>Kristina A.</given-names>
              </name>
              <xref ref-type="aff" rid="aff1">
                <sup>a</sup>
              </xref>
            </contrib>
            <contrib contrib-type="author">
              <name>
                <surname>Winkler</surname>
                <given-names>Wade C.</given-names>
              </name>
              <xref ref-type="aff" rid="aff3">
                <sup>b</sup>
              </xref>
              <xref ref-type="corresp" rid="cor1">
                <sup>2</sup>
              </xref>
            </contrib>
            <aff id="aff1"><sup>a</sup>Department of Microbiology and Molecular Genetics, and </aff>
            <aff id="aff2"><sup>c</sup>Division of Infectious Diseases, Department of Medicine, University of Texas Health Science Center, Houston, TX 77030; and </aff>
            <aff id="aff3"><sup>b</sup>Department of Biochemistry, University of Texas Southwestern Medical Center, Dallas, TX 75390</aff>
          </contrib-group>
          <author-notes>
            <corresp id="cor1"><sup>2</sup>To whom correspondence may be addressed. E-mail: <email>wade.winkler@utsouthwestern.edu</email> or <email>danielle.a.garsin@uth.tmc.edu</email></corresp>
          </author-notes>
          <pub-date pub-type="ppub">
            <day>17</day>
            <month>3</month>
            <year>2009</year>
          </pub-date>
          <pub-date pub-type="epub">
            <day>25</day>
            <month>2</month>
            <year>2009</year>
          </pub-date>
          <pub-date pub-type="pmc-release">
            <day>25</day>
            <month>2</month>
            <year>2009</year>
          </pub-date>
          <!-- PMC Release delay is 0 months and 0 days and was based on the
                epub date downloaded from Highwire. -->
          <volume>106</volume>
          <issue>11</issue>
          <fpage>4435</fpage>
          <lpage>4440</lpage>
          <history>
            <date date-type="received">
              <day>3</day>
              <month>12</month>
              <year>2008</year>
            </date>
          </history>
          <permissions>
            <license license-type="open-access">
              <license-p>Freely available online through the PNAS open access option.</license-p>
            </license>
          </permissions>
          <self-uri xlink:title="pdf" xlink:type="simple" xlink:href="zpq01109004435.pdf"/>
          <abstract>
            Abstract Text.
          </abstract>
          <kwd-group>
            <kwd>riboswitch</kwd>
            <kwd>2-component system</kwd>
          </kwd-group>
        </article-meta>
      </front>
    </article>
    </pmc-articleset>
  XML

  it "should not call the API if there are cached results" do
    expect(HttpUtilities).to_not receive(:post)

    cached = { references: {
        'ref-1' => { id_type: :pmcid, id:'PMC1234567890', info:{info_source:'cached', title:'cached title'} },
    } }
    process(cached)

    expect(ref_info[:info_source]).to eq('cached')
    expect(ref_info[:title] ).to eq('cached title')
  end

  it "should merge in the API results" do
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :pmcid, id:'PMC2647976', score:1.23, id_source:'test' } )

    expect(HttpUtilities).to receive(:post).and_return(sample_response)

    expect(ref_info).to eq({
                              id_source:           'test',
                              id:                  'PMC2647976',
                              id_type:             :pmcid,
                              score:               1.23,
                              info_source:         "NIH",
                              DOI:                 "10.1073/pnas.0812194106",
                              PMCID:               "PMC2647976",
                              PMID:                "19246383",
                              abstract:            "Abstract Text.",
                              author:              [{:given=>"Kristina A.", :family=>"Fox", :affiliation=>"Department of Microbiology and Molecular Genetics, and"},
                                                    {:given=>"Wade C.", :family=>"Winkler", :email=>"wade.winkler@utsouthwestern.edu", :affiliation=>"Department of Biochemistry, University of Texas Southwestern Medical Center, Dallas, TX 75390"}],
                              :"container-title"=> "Proceedings of the National Academy of Sciences of the United States of America",
                              issue:               "11",
                              issued:              [[2009, 2, 25]],
                              page:                "4435-4440",
                              subject:             ["Biological Sciences", "Biological Sciences - Microbiology"],
                              title:               "Multiple posttranscriptional regulatory mechanisms partner to control ethanolamine utilization",
                              volume:              "106",
                              publisher:           "National Academy of Sciences",
                          })
  end

  it "shouldn't fail for any missing data" do
    response = '<PubmedArticleSet><PubmedArticle></PubmedArticle></PubmedArticleSet>'

    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :pmcid, id:'PMC0451526538' } )

    expect(HttpUtilities).to receive(:post).and_return(response)

    expect(ref_info).to eq( id:'PMC0451526538', id_type: :pmcid)
  end

  it "shouldn't fail if there is no data" do
    response = '<PubmedArticleSet></PubmedArticleSet>'

    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :pmcid, id:'PMC0451526538' } )

    expect(HttpUtilities).to receive(:post).and_return(response)

    expect(ref_info).to eq( id:'PMC0451526538', id_type: :pmcid)
  end

  it "should handle missing results" do
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :pmcid, id:'PMC0451526538', score:1.23, id_source:'test' } )

    expect(HttpUtilities).to receive(:post).and_return('{}')

    expect(ref_info).to eq({
                                id_source:  'test',
                                id:         'PMC0451526538',
                                id_type:    :pmcid,
                                score:      1.23
                            })
  end

  it "should match multiple results even if they are out of order" do
    multiple_response = <<-XML
      <pmc-articleset>
        <article><front>
          <article-meta><article-id pub-id-type="pmc">2222222222</article-id></article-meta>
        </front></article>
        <article><front>
          <article-meta><article-id pub-id-type="pmc">1111111111</article-id></article-meta>
        </front></article>
      </pmc-articleset>
   XML

    refs 'First', 'Second'
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :pmcid, id:'PMC1111111111'},
                                                              'ref-2' => { id_type: :pmcid, id:'PMC2222222222'}  )

    expect(HttpUtilities).to receive(:post).and_return(multiple_response)

    expect(result[:references]['ref-1'][:info]).to eq({
                                                          id:          'PMC1111111111',
                                                          id_type:     :pmcid,
                                                          info_source: 'NIH',
                                                          PMCID:       'PMC1111111111',
                                                      })
    expect(result[:references]['ref-2'][:info]).to eq({
                                                          id:          'PMC2222222222',
                                                          id_type:     :pmcid,
                                                          info_source: 'NIH',
                                                          PMCID:       'PMC2222222222',
                                                      })
  end

  it "should not overwrite the type, id, score or id_source" do
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :pmcid, id:'PMC0451526538', score:1.23, id_source:'test' } )

    expect(HttpUtilities).to receive(:post).and_return(sample_response)

    expect(ref_info).to include(
                                    id_type:     :pmcid,
                                    id:          'PMC0451526538',
                                    id_source:   'test',
                                    score:       1.23
                                )
  end

  it "should include different types of authors" do
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :pmcid, id:'PMC0451526538' } )

    expect(HttpUtilities).to receive(:post).and_return(test_response('0451526538', <<-XML))
      <contrib-group>
        <!-- Literal -->
        <contrib contrib-type="author">
          <literal>PLOS Labs</literal>
        </contrib>
        <!-- Standard -->
        <contrib contrib-type="author">
          <name>
            <surname>Fox</surname>
            <given-names>Kristina A.</given-names>
          </name>
        </contrib>
        <!-- With affiliate -->
        <contrib contrib-type="author">
          <name>
            <surname>Ramesh</surname>
            <given-names>Arati</given-names>
          </name>
          <xref ref-type="aff" rid="aff1">
            <sup>b</sup>
          </xref>
        </contrib>
        <!-- With email -->
        <contrib contrib-type="author">
          <name>
            <surname>Winkler</surname>
            <given-names>Wade C.</given-names>
          </name>
          <xref ref-type="corresp" rid="cor1">
            <sup>2</sup>
          </xref>
        </contrib>
        <aff id="aff1"><sup>a</sup>Department of Microbiology and Molecular Genetics</aff>
      </contrib-group>
      <author-notes>
        <corresp id="cor1"><sup>2</sup>To whom correspondence may be addressed. E-mail:
          <email>wade.winkler@utsouthwestern.edu</email> or <email>danielle.a.garsin@uth.tmc.edu</email>
        </corresp>
      </author-notes>
    XML

    expect(ref_info[:author]).to eq([
                                        {:literal=>"PLOS Labs"},
                                        {:given=>"Kristina A.", :family=>"Fox"},
                                        {:given=>"Arati", :family=>"Ramesh", :affiliation=>"Department of Microbiology and Molecular Genetics"},
                                        {:given=>"Wade C.", :family=>"Winkler", :email=>"wade.winkler@utsouthwestern.edu"},
                                    ])

  end

  it "should include subjects and nested subjects" do
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :pmcid, id:'PMC0451526538' } )

    expect(HttpUtilities).to receive(:post).and_return(test_response('0451526538', <<-XML))
      <article-categories>
        <subj-group>
          <subject>Articles</subject>

          <subj-group>
            <subject>Biological Sciences</subject>

            <subj-group>
              <subject>Biochemistry</subject>
            </subj-group>
          </subj-group>

          <subj-group>
            <subject>Physical Sciences</subject>

            <subj-group>
              <subject>Chemistry</subject>
            </subj-group>
          </subj-group>

        </subj-group>
      </article-categories>
    XML

    expect(ref_info[:subject]).to eq(['Articles',
                                      'Articles - Biological Sciences', 'Articles - Biological Sciences - Biochemistry',
                                      'Articles - Physical Sciences', 'Articles - Physical Sciences - Chemistry',
                                     ])

  end

  it "should include markup in the title" do
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :pmcid, id:'PMC0451526538' } )

    expect(HttpUtilities).to receive(:post).and_return(test_response('0451526538', <<-XML))
      <title-group>
         <article-title>Title with <i>markup</i>.</article-title>
      </title-group>
    XML

    expect(ref_info[:title]).to eq('Title with <i>markup</i>.')
  end

  it "should include markup in the abstract" do
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :pmcid, id:'PMC0451526538' } )

    expect(HttpUtilities).to receive(:post).and_return(test_response('0451526538', <<-XML))
      <abstract>
      <p>With <i>Markup</i>.</p>
      </abstract>
    XML

    expect(ref_info[:abstract]).to eq('<p>With <i>Markup</i>.</p>')
  end

  context "should include the publication date" do

    it "should use the epub date first" do
      allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :pmcid, id:'PMC0451526538' } )

      expect(HttpUtilities).to receive(:post).and_return(test_response('0451526538', <<-XML))
        <pub-date pub-type="ppub">
          <day>17</day>
          <month>3</month>
          <year>2009</year>
        </pub-date>
        <pub-date pub-type="epub">
          <day>25</day>
          <month>2</month>
          <year>2009</year>
        </pub-date>
      XML

      expect(ref_info[:issued]).to eq([[2009,2,25]])
    end

    it "should fallback to the ppub date" do
      allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :pmcid, id:'PMC0451526538' } )

      expect(HttpUtilities).to receive(:post).and_return(test_response('0451526538', <<-XML))
        <pub-date pub-type="ppub">
          <day>17</day>
          <month>3</month>
          <year>2009</year>
        </pub-date>
      XML

      expect(ref_info[:issued]).to eq([[2009,3,17]])
    end

    it "should accept a missing day field" do
      allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :pmcid, id:'PMC0451526538' } )

      expect(HttpUtilities).to receive(:post).and_return(test_response('0451526538', <<-XML))
        <pub-date pub-type="epub">
          <month>2</month>
          <year>2009</year>
        </pub-date>
      XML

      expect(ref_info[:issued]).to eq([[2009,2]])
    end

  end

  context "page field" do

    it "should handle a start and end page" do
      allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :pmcid, id:'PMC0451526538' } )

      expect(HttpUtilities).to receive(:post).and_return(test_response('0451526538', <<-XML))
        <fpage>4435</fpage>
        <lpage>4440</lpage>
      XML

      expect(ref_info[:page]).to eq("4435-4440")
    end

    it "should not include the end page if it is the same as the start" do
      allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :pmcid, id:'PMC0451526538' } )

      expect(HttpUtilities).to receive(:post).and_return(test_response('0451526538', <<-XML))
        <fpage>4435</fpage>
        <lpage>4435</lpage>
      XML

      expect(ref_info[:page]).to eq("4435")
    end

    it "should not fail if the end page is missing" do
      allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :pmcid, id:'PMC0451526538' } )

      expect(HttpUtilities).to receive(:post).and_return(test_response('0451526538', <<-XML))
        <fpage>4435</fpage>
      XML

      expect(ref_info[:page]).to eq("4435")
    end

  end

end
