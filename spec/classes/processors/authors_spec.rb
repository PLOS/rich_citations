require 'spec_helper'

describe Processors::Authors do
  include Spec::ProcessorHelper

  def authors
    result[:paper][:authors]
  end

  it "should parse out the authors" do
    meta <<-EOS
      <contrib contrib-type="author">
        <surname>Jolie</surname><given-names>Angelina</given-names>
      </contrib>
      <contrib contrib-type="author">
        <surname>Roberts</surname><given-names>Julia</given-names>
      </contrib>
    EOS

    expect(authors).to eq([ {fullname:'Angelina Jolie'},
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

    expect(authors).to eq([ {fullname:'Angelina Jolie'}  ])
  end

  it "should include emails if available" do
    meta <<-EOS
      <contrib contrib-type="author">
        <surname>Jolie</surname><given-names>Angelina</given-names>
        <xref ref-type='corresp' rid='cor1'>
      </contrib>
      <corresp id="cor1">* E-mail: <email xlink:type="simple">a.jolie@plos.org</email></corresp>
    EOS

    expect(authors).to eq([ {fullname:'Angelina Jolie', email:'a.jolie@plos.org'}  ])
  end

  it "should include affilitions if available" do
    meta <<-EOS
      <contrib contrib-type="author">
        <surname>Jolie</surname><given-names>Angelina</given-names>
        <xref ref-type='aff' rid='aff1'>
      </contrib>
      <aff id="aff1"><addr-line>Hollywood</addr-line></aff>
    EOS

    expect(authors).to eq([ {fullname:'Angelina Jolie', affiliation:'Hollywood'}  ])
  end

end