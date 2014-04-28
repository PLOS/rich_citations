require 'spec_helper'

describe Plos::PaperParser do

  before do
    allow(Plos::InfoResolver).to receive(:RESOLVERS).and_return(Plos::InfoResolver::TEST_RESOLVERS)
  end

  def parts
    @parts ||= {}
  end

  def doi(doi)
    parts[:doi] = doi
  end

  def refs(refs)
    parts[:refs] = refs
  end

  def meta (meta)
    parts[:meta]  = meta
  end

  def wrapped_xml(parts)
    <<-EOS
      <root>
        <article-id pub-id-type='doi'>#{parts[:doi] || '10.12345/1234.12345'}</article-id>
        <article-meta>#{parts[:meta]}</article-meta>
        <body>
        </body>
        <ref-list>#{parts[:refs]}</ref-list>
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
      refs '<ref>Some Reference</ref><ref>Another Reference</ref>'

      expect(result[:references]).to have(2).items
      expect(result[:references][1]).to eq(:info=>{:text=>"Some Reference", :score=>2.5}, :median_co_citations=>-1, :zero_mentions=>true)
      expect(result[:references][2]).to eq(:info=>{:text=>"Another Reference", :score=>2.5}, :median_co_citations=>-1, :zero_mentions=>true)
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

      refs '<ref>Some Reference</ref>'
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
      expect(reference[:self_citations]).to eq(['Angelina Jolie [name, email]'])
    end

    it "should note self citations based on name and email with the same affiliation" do
      resolve_author!(fullname:'Angelina Jolie', email:'a.jolie@hollywood.com', affiliation:'Hollywood')
      expect(reference[:self_citations]).to eq(['Angelina Jolie [name, email,affiliation]'])
    end

  end

end
