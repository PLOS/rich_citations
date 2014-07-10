require 'spec_helper'

describe Processors::NormalizeAuthorNames do
  include Spec::ProcessorHelper

  def resolve_authors!(*authors)
    refs 'First'
    expect(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { author: authors })
  end

  def authors
    reference = result[:references].values.first
    reference[:info][:author]
  end

  it "should normalize authors in the citing paper info" do
    meta <<-META
      <contrib contrib-type="author">
        <surname>JOLIE</surname><given-names>ANGELINA</given-names>
      </contrib>
      <contrib contrib-type="author">
        <literal>ROBERTS, JULIA</literal>
      </contrib>
    META

    expect( result[:paper][:author] ).to eq( [
                                              {given:"Angelina", family:"Jolie"},
                                              {literal:"Roberts, Julia"}
                                            ])
  end

  it "should normalize authors in the cited paper's info" do
    resolve_authors!( {given:"ANGELINA", family:"JOLIE"},
                      {literal:"ROBERTS, JULIA"}           )

    expect( authors ).to eq([
                                  {given:"Angelina", family:"Jolie"},
                                  {literal:"Roberts, Julia"}
                              ])
  end

  it "should normalize a literal" do
    resolve_authors!( {literal:"ROBERTS, JULIA"},
                      {literal:"ANGELINA JOLIE"}    )

    expect( authors ).to eq([
                                {literal:"Roberts, Julia"},
                                {literal:"Angelina Jolie"},
                            ])
  end

  it "should only normalize a literal if it is all caps" do
    resolve_authors!( {literal:"ROBERTS, Julia"} )

    expect( authors ).to eq([ {literal:"ROBERTS, Julia"} ])
  end

  it "should normalize a given/family pair" do
    resolve_authors!( {given:"ANGELINA BRAD", family:"JOLIE"} )

    expect( authors ).to eq([ {given:"Angelina Brad", family:"Jolie"} ])
  end

  it "should not normalize a given/family pair if there are non caps" do
    resolve_authors!(
                      {given:"ANGELINA", family:"JoliE"},
                      {given:"ANGELINA", family:"Jolie"},
                      {given:"AngelinA", family:"Jolie"},
                      {given:"AngelinA", family:"JOLIE"},
    )

    expect( authors ).to eq([
                                {given:"ANGELINA", family:"JoliE"},
                                {given:"ANGELINA", family:"Jolie"},
                                {given:"AngelinA", family:"Jolie"},
                                {given:"AngelinA", family:"JOLIE"},
                            ])
  end

  it "should not normalize something that looks like initials" do
    resolve_authors!( {given:"AB", family:"JOLIE"}, {given:"J.A.X.", family:"ROBERTS"} )

    expect( authors ).to eq([ {given:"AB", family:"Jolie"}, {given:"J.A.X.", family:"Roberts"} ])
  end

end