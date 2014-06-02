require 'spec_helper'

describe Processors::PaperInfo do
  include Spec::ProcessorHelper

  it "should have a title" do
    body <<-XML
      <front>
      <article-meta>
      <title-group>
        <article-title>Sexy Faces in a Male Paper Wasp</article-title>
      </title-group>
      </article-meta>
      </front>
    XML
    expect(result[:paper][:title]).to eq('Sexy Faces in a Male Paper Wasp')
  end

  it "should have a word count" do
    body 'here is <b>some</b> text'
    expect(result[:paper][:word_count]).to eq(4)
  end

  it "cleanup the paper object" do
    cleanup(paper:{a:1,b:nil,c:3})
    expect(result[:paper]).to eq(a:1, c:3)
  end

end