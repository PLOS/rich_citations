require 'spec_helper'

describe Processors::SelfCitations do
  include Spec::ProcessorHelper

  before do
    meta <<-EOM
      <contrib contrib-type="author">
        <surname>Jolie</surname><given-names>Angelina</given-names>
        <xref ref-type='aff' rid='aff1' />
        <xref ref-type='corresp' rid='corr1' />
      </contrib>
      <contrib contrib-type="author">
        <literal>Roberts, Julia</literal>
      </contrib>
      <aff id="aff1"><addr-line>Hollywood</addr-line></aff>
      <corresp id="corr1">a.jolie@hollywood.com</corresp>
    EOM

    refs 'Some Reference'
  end

  def resolve_author!(author)
    expect(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { author:[author] })
  end

  def reference
    result[:references].values.first
  end

  it "should identify a self citation based on a given and family name" do
    resolve_author!(family:'Jolie', given:'Angelina')
    expect(reference[:self_citations]).to eq(['Jolie, Angelina [name]'])
  end

  it "should identify a self citation based on a literal name" do
    resolve_author!(literal:'Roberts, Julia')
    expect(reference[:self_citations]).to eq(['Roberts, Julia [name]'])
  end

  it "should work when comparing a literal name to a given and family" do
    resolve_author!(family:'Roberts', given:'Julia')
    expect(reference[:self_citations]).to eq(['Roberts, Julia [name]'])
  end

  it "should work when comparing a given and family name with a literal name" do
    resolve_author!(literal:'Jolie, Angelina')
    expect(reference[:self_citations]).to eq(['Jolie, Angelina [name]'])
  end

  it "should return nil if there are no self citations" do
    resolve_author!(given:'Audrey', family:'Hepburn')
    expect(reference[:self_citations]).to be_nil
  end

  it "should identify a self citation if the affiliations are different" do
    resolve_author!(family:'Jolie', given:'Angelina', affiliation:'Baseball')
    expect(reference[:self_citations]).to be_nil
  end

  it "should note a self citation if the affiliations are the same" do
    resolve_author!(family:'Jolie', given:'Angelina', affiliation:'Hollywood')
    expect(reference[:self_citations]).to eq(['Jolie, Angelina [name,affiliation]'])
  end

  it "should match self citations based on email" do
    resolve_author!(family:'Jolie', given:'A.', email:'a.jolie@hollywood.com')
    expect(reference[:self_citations]).to eq(['Jolie, Angelina [email]'])
  end

  it "should not match self citations with differing emails" do
    resolve_author!(family:'Jolie', given:'A.', email:'jolie@hollywood.com')
    expect(reference[:self_citations]).to be_nil
  end

  it "should match self citations based on name and email" do
    resolve_author!(family:'Jolie', given:'Angelina', email:'a.jolie@hollywood.com')
    expect(reference[:self_citations]).to eq(['Jolie, Angelina [name,email]'])
  end

  it "should note self citations based on name and email with the same affiliation" do
    resolve_author!(family:'Jolie', given:'Angelina', email:'a.jolie@hollywood.com', affiliation:'Hollywood')
    expect(reference[:self_citations]).to eq(['Jolie, Angelina [name,email,affiliation]'])
  end

end