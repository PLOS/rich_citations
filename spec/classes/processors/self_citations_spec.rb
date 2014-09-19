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

describe Processors::SelfCitations do
  include Spec::ProcessorHelper

  before do
    meta <<-EOM
      <contrib contrib-type="author">
        <surname>Jolie</surname><given-names>Angelina</given-names>
        <xref ref-type='aff' rid='aff1' />
        <xref ref-type='corresp' rid='corr1' />
      </contrib>
      <aff id="aff1"><addr-line>Hollywood</addr-line></aff>
      <corresp id="corr1">a.jolie@hollywood.com</corresp>
      <contrib contrib-type="author">
        <literal>Roberts, Julia</literal>
      </contrib>
      <contrib contrib-type="author">
        <literal>Sandra Bullock</literal>
      </contrib>
      <contrib contrib-type="author">
        <literal>Kidman, N. M.</literal>
      </contrib>
    EOM

    refs 'Some Reference'
  end

  def resolve_author!(author)
    expect(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { author:[author] })
  end

  def reference
    result[:references].first
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

  it "should work when comparing a literal name in the given family format with a given and family" do
    resolve_author!(family:'Bullock', given:'Sandra')
    expect(reference[:self_citations]).to eq(['Sandra Bullock [name]'])
  end

  it "should work when comparing a given and family name with a literal name" do
    resolve_author!(literal:'Jolie, Angelina')
    expect(reference[:self_citations]).to eq(['Jolie, Angelina [name]'])
  end

  it "should work when comparing a given and family name with a literal name in give family format" do
    resolve_author!(literal:'Angelina Jolie')
    expect(reference[:self_citations]).to eq(['Jolie, Angelina [name]'])
  end

  it "should work when comparing a literal with a literal name in give family format" do
    resolve_author!(literal:'Jolie, Angelina')
    expect(reference[:self_citations]).to eq(['Jolie, Angelina [name]'])
  end

  it "should work when comparing a literal in th given, family format with a literal name" do
    resolve_author!(literal:'Bullock, Sandra')
    expect(reference[:self_citations]).to eq(['Sandra Bullock [name]'])
  end

  it "should ignore spaces and punctuation in initials" do
    resolve_author!(literal:'Kidman, NM')
    expect(reference[:self_citations]).to eq(['Kidman, N. M. [name]'])
  end

  it "should ignore case differences" do
    resolve_author!(family:'joliE', given:'angelinA')
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
