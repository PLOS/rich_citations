require 'spec_helper'

describe Plos::PaperParser do

  def result
    @result
  end

  def wrapped_xml(string)
    <<-EOS
    <root>
      <article-id pub-id-type='doi'>10.12345/1234.12345</article-id>
      <body></body>
      #{string}
    </root>
    EOS
  end

  def parse(xml)
    xml = Nokogiri.XML(xml)
    @result = Plos::PaperParser.new(xml).paper_info
  end

  it "should have a DOI" do
    parse(wrapped_xml(''))
    expect(result[:doi]).to eq('10.12345/1234.12345')
  end

  context "authors" do

    it "should parse out the authors" do
      parse wrapped_xml <<-EOS
              <article-meta>
                 <contrib contrib-type="author">
                   <surname>Jolie</surname><given-names>Angelina</given-names>
                 </contrib>
                 <contrib contrib-type="author">
                   <surname>Roberts</surname><given-names>Julia</given-names>
                 </contrib>
              </article-meta>
            EOS

      expect(result[:authors]).to eq([
                                        {fullname:'Angelina Jolie'},
                                        {fullname: 'Julia Roberts' }  ])
    end

    it "should ignore non-authors" do
      parse wrapped_xml <<-EOS
              <article-meta>
                 <contrib contrib-type="author">
                   <surname>Jolie</surname><given-names>Angelina</given-names>
                 </contrib>
                 <contrib contrib-type="editor">
                   <surname>Jackson</surname><given-names>Randy</given-names>
                 </contrib>
              </article-meta>
      EOS

      expect(result[:authors]).to eq([
                                         {fullname:'Angelina Jolie'}  ])
    end

    it "should include emails if available" do
      parse wrapped_xml <<-EOS
              <article-meta>
                 <contrib contrib-type="author">
                   <surname>Jolie</surname><given-names>Angelina</given-names>
                   <xref xref-type='corresp' rid='cor1'>
                 </contrib>
                 <corresp id="cor1">* E-mail: <email xlink:type="simple">a.jolie@plos.org</email></corresp>
              </article-meta>
      EOS

      expect(result[:authors]).to eq([
                                         {fullname:'Angelina Jolie', email:'a.jolie@plos.org'}  ])
    end

    it "should include affilitions if available" do
      parse wrapped_xml <<-EOS
              <article-meta>
                 <contrib contrib-type="author">
                   <surname>Jolie</surname><given-names>Angelina</given-names>
                   <xref xref-type='aff' rid='aff1'>
                 </contrib>
                 <aff id="cor1"><addr-line>Hollywood</addr-line></aff>
              </article-meta>
      EOS

      expect(result[:authors]).to eq([
                                         {fullname:'Angelina Jolie', affiliation:'Hollywood'}  ])
    end

  end

end
