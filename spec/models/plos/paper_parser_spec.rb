require 'spec_helper'

describe Plos::PaperParser do

  before do
    allow(Plos::InfoResolver).to receive(:resolvers).and_return(Plos::InfoResolver::TEST_RESOLVERS)
  end

  def parts
    @parts ||= {}
  end

  def doi(doi)
    parts[:doi] = doi
  end

  def refs(*refs)
    (parts[:refs] ||= []).concat(refs)
  end

  def meta (meta)
    (parts[:meta] ||= '') << meta
  end

  def body (body)
    (parts[:body] ||= '') << body
  end

  def cite(number)
    "<xref ref-type='bibr' rid='ref-#{number}'>[#{number}]</xref>"
  end

  def ref_list
    if parts[:refs]
     parts[:refs].map.with_index{ |r,i| "<ref id='ref-#{i+1}'>#{r}</ref>" }.join
    end
  end

  def wrapped_xml(parts)
    <<-EOS
      <root>
        <article-id pub-id-type='doi'>#{parts[:doi] || '10.12345/1234.12345'}</article-id>
        <article-meta>#{parts[:meta]}</article-meta>
        <body>#{parts[:body]}</body>
        <ref-list>#{ref_list}</ref-list>
      </root>
    EOS
  end

  def result
    @result ||= begin
      xml = Nokogiri.XML(wrapped_xml(parts))
      @parser = Plos::PaperParser.new(xml)
      @parser.paper_info
    end
  end

  def reference
    result[:references].first.last
  end

  it "should have a DOI" do
    doi '10.12345/1234.12345'
    expect(result[:doi]).to eq('10.12345/1234.12345')
  end

  context "citations" do

    it "should have a citation" do
      refs 'Some Reference', 'Another Reference'

      expect(result[:references]).to have(2).items
      expect(result[:references][1]).to eq(id:'ref-1', info:{text: "Some Reference"},    :median_co_citations=>-1, :zero_mentions=>true)
      expect(result[:references][2]).to eq(id:'ref-2', info:{text: "Another Reference"}, :median_co_citations=>-1, :zero_mentions=>true)
    end

  end

  context "authors" do

    it "should parse out the authors" do
      meta <<-EOS
        <contrib contrib-type="author">
          <surname>Jolie</surname><given-names>Angelina</given-names>
        </contrib>
        <contrib contrib-type="author">
          <surname>Roberts</surname><given-names>Julia</given-names>
        </contrib>
      EOS

      expect(result[:authors]).to eq([ {fullname:'Angelina Jolie'},
                                       {fullname: 'Julia Roberts' }  ])
    end

    it "should ignore non-authors" do
      meta <<-EOS
        <contrib contrib-type="author">
          <surname>Jolie</surname><given-names>Angelina</given-names>
        </contrib>
       <contrib contrib-type="editor">
          <surname>Jackson</surname><given-names>Randy</given-names>
        </contrib>
      EOS

      expect(result[:authors]).to eq([ {fullname:'Angelina Jolie'}  ])
    end

    it "should include emails if available" do
      meta <<-EOS
        <contrib contrib-type="author">
          <surname>Jolie</surname><given-names>Angelina</given-names>
          <xref ref-type='corresp' rid='cor1'>
        </contrib>
        <corresp id="cor1">* E-mail: <email xlink:type="simple">a.jolie@plos.org</email></corresp>
      EOS

      expect(result[:authors]).to eq([ {fullname:'Angelina Jolie', email:'a.jolie@plos.org'}  ])
    end

    it "should include affilitions if available" do
      meta <<-EOS
        <contrib contrib-type="author">
          <surname>Jolie</surname><given-names>Angelina</given-names>
          <xref ref-type='aff' rid='aff1'>
        </contrib>
        <aff id="aff1"><addr-line>Hollywood</addr-line></aff>
      EOS

      expect(result[:authors]).to eq([ {fullname:'Angelina Jolie', affiliation:'Hollywood'}  ])
    end

  end

  context "self citations" do

    before do
      meta <<-EOM
        <contrib contrib-type="author">
          <surname>Jolie</surname><given-names>Angelina</given-names>
          <xref ref-type='aff' rid='aff1'>
          <xref ref-type='corresp' rid='corr1'>
       </contrib>
        <aff id="aff1"><addr-line>Hollywood</addr-line></aff>
        <corresp id="corr1">a.jolie@hollywood.com</corresp>
      EOM

      refs 'Some Reference'
    end

    def resolve_author!(author)
      expect(Plos::InfoResolver).to receive(:resolve).and_return(1 => { authors:[author] })
    end

    it "should identify a self citation" do
      resolve_author!(fullname:'Angelina Jolie')
      expect(reference[:self_citations]).to eq(['Angelina Jolie [name]'])
    end

    it "should return nil if there are no self citations" do
      resolve_author!(fullname:'Audrey Hepburn')
      expect(reference[:self_citations]).to be_nil
    end

    it "should identify a self citation if the affiliations are different" do
      resolve_author!(fullname:'Angelina Jolie', affiliation:'Baseball')
      expect(reference[:self_citations]).to be_nil
    end

    it "should note a self citation if the affiliations are the same" do
      resolve_author!(fullname:'Angelina Jolie', affiliation:'Hollywood')
      expect(reference[:self_citations]).to eq(['Angelina Jolie [name,affiliation]'])
    end

    it "should match self citations based on email" do
      resolve_author!(fullname:'A Jolie', email:'a.jolie@hollywood.com')
      expect(reference[:self_citations]).to eq(['A Jolie [email]'])
    end

    it "should not match self citations with differing emails" do
      resolve_author!(fullname:'A Jolie', email:'jolie@hollywood.com')
      expect(reference[:self_citations]).to be_nil
    end

    it "should match self citations based on name and email" do
      resolve_author!(fullname:'Angelina Jolie', email:'a.jolie@hollywood.com')
      expect(reference[:self_citations]).to eq(['Angelina Jolie [name,email]'])
    end

    it "should note self citations based on name and email with the same affiliation" do
      resolve_author!(fullname:'Angelina Jolie', email:'a.jolie@hollywood.com', affiliation:'Hollywood')
      expect(reference[:self_citations]).to eq(['Angelina Jolie [name,email,affiliation]'])
    end

  end

  context "citation context" do

    before do
      refs 'A Reference'
    end

    it "should provide citation context" do
      body "Some text #{cite(1)} More text"
      expect(result[:groups][0][:context]).to eq('Some text [1] More text')
    end

    it "should truncate ellipses" do
      body "A lot of very long text before the citation #{cite(1)} and then more very long text after the citation."
      expect(result[:groups][0][:context]).to eq("\u2026text before the citation [1] and then more very long text\u2026")
    end

    it "should be limited to the nearest section" do
      body "<sec>abc<sec>"
      body "Some text #{cite(1)} More text"
      body "</sec>def</sec>"
      expect(result[:groups][0][:context]).to eq('Some text [1] More text')
    end

    it "should be limited to the nearest paragraph" do
      body "<sec>abc<P>"
      body "Some text #{cite(1)} More text"
      body "</P>def</sec>"
      expect(result[:groups][0][:context]).to eq('Some text [1] More text')
    end

  end

end
