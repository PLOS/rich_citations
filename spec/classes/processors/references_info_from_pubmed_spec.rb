require 'spec_helper'

describe Processors::ReferencesInfoFromPubmed do
  include Spec::ProcessorHelper

  it "should call the API" do
    refs 'First', 'Second', 'Third'
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :pmid, id:'1111111111' },
                                                              'ref-2' => { source:'none'},
                                                              'ref-3' => { id_type: :pmid, id:'2222222222' })

    expect(HttpUtilities).to receive(:get).with("http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&retmode=xml&id=1111111111,2222222222", :xml).and_return('{}')

    process
  end

  complete_response = <<-XML
<?xml version="1.0"?>
<!DOCTYPE PubmedArticleSet PUBLIC "-//NLM//DTD PubMedArticle, 1st January 2014//EN" "http://www.ncbi.nlm.nih.gov/corehtml/query/DTD/pubmed_140101.dtd">
<PubmedArticleSet>
<PubmedArticle>
    <MedlineCitation Owner="NLM" Status="MEDLINE">
        <PMID Version="1">12466850</PMID>
        <DateCreated>
            <Year>2002</Year>
            <Month>12</Month>
            <Day>05</Day>
        </DateCreated>
        <DateCompleted>
            <Year>2002</Year>
            <Month>12</Month>
            <Day>27</Day>
        </DateCompleted>
        <DateRevised>
            <Year>2009</Year>
            <Month>11</Month>
            <Day>19</Day>
        </DateRevised>
        <Article PubModel="Print">
            <Journal>
                <ISSN IssnType="Print">0028-0836</ISSN>
                <JournalIssue CitedMedium="Print">
                    <Volume>420</Volume>
                    <Issue>6915</Issue>
                    <PubDate>
                        <Year>2002</Year>
                        <Month>Dec</Month>
                        <Day>5</Day>
                    </PubDate>
                </JournalIssue>
                <Title>Nature</Title>
                <ISOAbbreviation>Nature</ISOAbbreviation>
            </Journal>
            <ArticleTitle>Initial sequencing and comparative analysis of the mouse genome.</ArticleTitle>
            <Pagination>
                <MedlinePgn>520-62</MedlinePgn>
            </Pagination>
            <Abstract>
                <AbstractText>Abstract Text.</AbstractText>
            </Abstract>
            <AuthorList CompleteYN="Y">
                <Author ValidYN="Y">
                    <CollectiveName>Mouse Genome Sequencing Consortium</CollectiveName>
                    <Affiliation>Genome Sequencing Center. waterston@gs.washington.edu</Affiliation>
                </Author>
                <Author ValidYN="Y">
                    <LastName>Waterston</LastName>
                    <ForeName>Robert H</ForeName>
                    <Initials>RH</Initials>
                </Author>
                <Author ValidYN="Y">
                    <LastName>Lindblad-Toh</LastName>
                    <ForeName>Kerstin</ForeName>
                    <Initials>K</Initials>
                </Author>
            </AuthorList>
            <Language>eng</Language>
            <PublicationTypeList>
                <PublicationType>Comparative Study</PublicationType>
                <PublicationType>Journal Article</PublicationType>
                <PublicationType>Research Support, Non-U.S. Gov't</PublicationType>
            </PublicationTypeList>
        </Article>
        <MedlineJournalInfo>
            <Country>England</Country>
            <MedlineTA>Nature</MedlineTA>
            <NlmUniqueID>0410462</NlmUniqueID>
            <ISSNLinking>0028-0836</ISSNLinking>
        </MedlineJournalInfo>
        <ChemicalList>
            <Chemical>
                <RegistryNumber>0</RegistryNumber>
                <NameOfSubstance>Proteome</NameOfSubstance>
            </Chemical>
            <Chemical>
                <RegistryNumber>0</RegistryNumber>
                <NameOfSubstance>RNA, Untranslated</NameOfSubstance>
            </Chemical>
        </ChemicalList>
        <CitationSubset>IM</CitationSubset>
        <CommentsCorrectionsList>
            <CommentsCorrections RefType="CommentIn">
                <RefSource>Nature. 2002 Dec 5;420(6915):512-4</RefSource>
                <PMID Version="1">12466846</PMID>
            </CommentsCorrections>
            <CommentsCorrections RefType="CommentIn">
                <RefSource>Nat Biotechnol. 2003 Jan;21(1):31-2</RefSource>
                <PMID Version="1">12511904</PMID>
            </CommentsCorrections>
            <CommentsCorrections RefType="CommentIn">
                <RefSource>Nature. 2002 Dec 5;420(6915):515-6</RefSource>
                <PMID Version="1">12466847</PMID>
            </CommentsCorrections>
        </CommentsCorrectionsList>
        <MeshHeadingList>
            <MeshHeading>
                <DescriptorName MajorTopicYN="N">Animals</DescriptorName>
            </MeshHeading>
            <MeshHeading>
                <DescriptorName MajorTopicYN="N">Base Composition</DescriptorName>
            </MeshHeading>
            <MeshHeading>
                <DescriptorName MajorTopicYN="N">Chromosomes, Mammalian</DescriptorName>
                <QualifierName MajorTopicYN="Y">genetics</QualifierName>
            </MeshHeading>
        </MeshHeadingList>
    </MedlineCitation>
    <PubmedData>
        <History>
            <PubMedPubDate PubStatus="pubmed">
                <Year>2002</Year>
                <Month>12</Month>
                <Day>6</Day>
                <Hour>4</Hour>
                <Minute>0</Minute>
            </PubMedPubDate>
            <PubMedPubDate PubStatus="medline">
                <Year>2002</Year>
                <Month>12</Month>
                <Day>28</Day>
                <Hour>4</Hour>
                <Minute>0</Minute>
            </PubMedPubDate>
            <PubMedPubDate PubStatus="received">
                <Year>2002</Year>
                <Month>Sep</Month>
                <Day>18</Day>
            </PubMedPubDate>
            <PubMedPubDate PubStatus="accepted">
                <Year>2002</Year>
                <Month>Oct</Month>
                <Day>31</Day>
            </PubMedPubDate>
            <PubMedPubDate PubStatus="entrez">
                <Year>2002</Year>
                <Month>12</Month>
                <Day>6</Day>
                <Hour>4</Hour>
                <Minute>0</Minute>
            </PubMedPubDate>
        </History>
        <PublicationStatus>ppublish</PublicationStatus>
        <ArticleIdList>
            <ArticleId IdType="pubmed">0451526538</ArticleId>
            <ArticleId IdType="doi">10.1038/nature01262</ArticleId>
            <ArticleId IdType="pii">nature01262</ArticleId>
            <ArticleId IdType="pmc">PMC111111</ArticleId>
        </ArticleIdList>
    </PubmedData>
</PubmedArticle>
</PubmedArticleSet>
  XML

  it "should not call the API if there are cached results" do
    refs 'First'
    expect(HttpUtilities).to_not receive(:get)

    cached = { references: {
        'ref-1' => { id_type: :pmid, id:'1234567890', info:{source:'cached', title:'cached title'} },
    } }
    process(cached)

    expect(result[:references]['ref-1'][:info][:source]).to eq('cached')
    expect(result[:references]['ref-1'][:info][:title] ).to eq('cached title')
  end

  it "should merge in the API results" do
    refs 'First'
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :pmid, id:'0451526538', score:1.23, ref_source:'test' } )

    expect(HttpUtilities).to receive(:get).and_return(complete_response)

    expect(result[:references]['ref-1'][:info]).to eq({
                                                          ref_source:          'test',
                                                          id:                  '0451526538',
                                                          id_type:             :pmid,
                                                          score:               1.23,
                                                          source:              "NIH",
                                                          DOI:                 "10.1038/nature01262",
                                                          PMCID:               "PMC111111",
                                                          PMID:                "0451526538",
                                                          abstract:            "Abstract Text.",
                                                          author:              [{:affiliation=>"Genome Sequencing Center.", :literal=>"Mouse Genome Sequencing Consortium", :email=>"waterston@gs.washington.edu"},
                                                                                {:famiy=>"Waterston", :given=>"Robert H", :initials=>"RH"},
                                                                                {:famiy=>"Lindblad-Toh", :given=>"Kerstin", :initials=>"K"}],
                                                          :"container-title"=> "Nature",
                                                          :"container-type"=>  "Comparative Study",
                                                          issue:               "6915",
                                                          issued:              [[2002, 12, 6]],
                                                          page:                "520-62",
                                                          subject:             ["Animals", "Base Composition", "Chromosomes, Mammalian - genetics"],
                                                          title:               "Initial sequencing and comparative analysis of the mouse genome.",
                                                          volume:              "420",
                                                      })
  end

  it "shouldn't fail for any missing data" do
    response = '<PubmedArticleSet><PubmedArticle></PubmedArticle></PubmedArticleSet>'

    refs 'First'
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :pmid, id:'0451526538' } )

    expect(HttpUtilities).to receive(:get).and_return(response)

    expect(result[:references]['ref-1'][:info]).to eq( id:'0451526538', id_type: :pmid)
  end

  it "shouldn't fail if there is no data" do
    response = '<PubmedArticleSet></PubmedArticleSet>'

    refs 'First'
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :pmid, id:'0451526538' } )

    expect(HttpUtilities).to receive(:get).and_return(response)

    expect(result[:references]['ref-1'][:info]).to eq( id:'0451526538', id_type: :pmid)
  end

  it "should handle missing results" do
    refs 'First'
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :pmid, id:'0451526538', score:1.23, ref_source:'test' } )

    expect(HttpUtilities).to receive(:get).and_return('{}')

    expect(result[:references]['ref-1'][:info]).to eq({
                                                          ref_source: 'test',
                                                          id:         '0451526538',
                                                          id_type:    :pmid,
                                                          score:      1.23
                                                      })
  end

  it "should match multiple results even if they are out of order" do
    multiple_response = <<-XML
     <PubmedArticleSet>
       <PubmedArticle>
         <PubmedData>
           <ArticleIdList> <ArticleId IdType="pubmed">2222222222</ArticleId></ArtileIdList>
         </PubmedData>
       </PubmedArticle>
       <PubmedArticle>
         <PubmedData>
           <ArticleIdList> <ArticleId IdType="pubmed">1111111111</ArticleId></ArtileIdList>
         </PubmedData>
       </PubmedArticle>
     </PubmedArticleSet>
   XML

    refs 'First', 'Second'
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :pmid, id:'1111111111'},
                                                              'ref-2' => { id_type: :pmid, id:'2222222222'}  )

    expect(HttpUtilities).to receive(:get).and_return(multiple_response)

    expect(result[:references]['ref-1'][:info]).to eq({
                                                          id:         '1111111111',
                                                          id_type:    :pmid,
                                                          source:     'NIH',
                                                          PMID:       '1111111111',
                                                      })
    expect(result[:references]['ref-2'][:info]).to eq({
                                                          id:         '2222222222',
                                                          id_type:    :pmid,
                                                          source:     'NIH',
                                                          PMID:       '2222222222',
                                                      })
  end

  it "should not overwrite the type, id, score or ref_source" do
    refs 'First'
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :pmid, id:'0451526538', score:1.23, ref_source:'test' } )

    expect(HttpUtilities).to receive(:get).and_return(complete_response)

    expect(result[:references]['ref-1'][:info]).to include(
                                                          id_type:     :pmid,
                                                          id:          '0451526538',
                                                          ref_source:  'test',
                                                          score:       1.23
                                                      )
  end

end
