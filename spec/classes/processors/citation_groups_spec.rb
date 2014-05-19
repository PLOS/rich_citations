require 'spec_helper'

describe Processors::CitationGroups do
  include Spec::ProcessorHelper

  before do
    refs 'First', 'Second', 'Third', 'Fourth', 'Fifth', 'Sixth', 'Seventh', 'Eighth', 'Ninth', 'Tenth', 'Eleventh'
  end

  it "should add a citation group" do
    body "some text #{cite(2)} with a reference."
    expect( result[:groups] ).to eq( [ {:count=>1, :references=>[2]} ] )
  end

  it "should add multiple citation groups" do
    body "some text #{cite(2)} with a reference."
    body "more text #{cite(3)} with a reference."
    expect( result[:groups] ).to eq( [ {:count=>1, :references=>[2]}, {:count=>1, :references=>[3]} ] )
  end

  it "should create a group for adjacent citations" do
    body "some text #{cite(2)}#{cite(4)} with a reference."
    expect( result[:groups] ).to eq( [ {:count=>2, :references=>[2,4]} ] )
  end

  it "should create a group for citations seoparated by a comma" do
    body "some text #{cite(2)}, #{cite(4)} with a reference."
    expect( result[:groups] ).to eq( [ {:count=>2, :references=>[2,4]} ] )
  end

  it "should create a group for a citation range" do
    body "some text #{cite(2)} - #{cite(4)} with a reference."
    expect( result[:groups] ).to eq( [ {:count=>3, :references=>[2,3,4]} ] )
  end

  it "should create a group with combined citations" do
    body "some text #{cite(1)}, #{cite(3)}-#{cite(5)}, #{cite(7)}, #{cite(9)}-#{cite(11)} with a reference."
    expect( result[:groups] ).to eq( [ {:count=>8, :references=>[1, 3,4,5, 7, 9,10,11]} ] )
  end

  it "should remove nil items during cleanup" do
    cleanup( { groups: [
        { a:1, b:nil, c:3}
    ] } )

    expect(result[:groups]).to eq( [ { a:1, c:3 } ] )
  end

  it "should remove nodes during cleanup" do
    cleanup( { groups: [
                           { a:1, nodes:999}
                       ] } )

    expect(result[:groups]).to eq( [ { a:1 } ] )
  end

end