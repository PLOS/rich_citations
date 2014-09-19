# coding: utf-8
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

describe Processors::NormalizeAuthorNames do
  include Spec::ProcessorHelper

  def resolve_authors!(*authors)
    refs 'First'
    expect(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { author: authors })
  end

  def authors
    reference = result[:references].first
    reference[:bibliographic][:author]
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

    expect( result[:bibliographic][:author] ).to eq( [
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

  it "should normalize accents correctly" do
    resolve_authors!( {family:"ÓNALDO", given:"JOSÉ DANIEL"} )

    expect( authors ).to eq([ {family:"Ónaldo", given:"José Daniel"} ])
  end

end
