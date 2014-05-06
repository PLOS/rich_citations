require 'spec_helper'

describe Plos::XmlUtilities do
  subject { Plos::XmlUtilities }

  def x(text)
    Nokogiri::XML(text)
  end

  describe "#text" do

    it "should return the text" do
      xml = x(<<-EOX.strip_heredoc
             <root>
             something
             <body>
             <a>text</a>
             more
             </body>
             else
             </root>
             EOX
      )

      expect( subject.text( xml.css('body') ) ).to eq("text\nmore")
    end

  end

  describe "#spaced_text" do

    it "should return the text with spaces" do
      xml = x(<<-EOX.strip_heredoc
             <root>
             something
             <node><first>First</first><last>Last</last></node>
             else
             </root>
      EOX
      )

      expect( subject.spaced_text( xml.css('node') ) ).to eq("First Last")
    end

    it "should normalize leading, tracing and between whitespace" do
      xml = x(<<-EOX.strip_heredoc
             <root>
             <node> <a>A</a>\n<a> B \n</a><a>C</a>\t<a>D</a>\n\t </node>
             </root>
      EOX
      )

      expect( subject.spaced_text( xml.css('node') ) ).to eq("A B C D")
    end

  end

  describe "#text_before" do

    before do
      @xml = x(<<-EOX.strip_heredoc
             <root>
             <body> <a>A</a> <b>B</b> <c> C </c> <d>D</d> <e>E</e> </body>
             <other />
             </root>
      EOX
      )
    end

    it "should return the text before the node" do
      expect( subject.text_before( @xml.css('body'), @xml.css('c').first ) ).to eq('A B ')
    end

    it "it should return '' if for the first node" do
      expect( subject.text_before( @xml.css('body'), @xml.css('a').first ) ).to eq('')
    end

    it "it should return nil if node is not found" do
      expect( subject.text_before( @xml.css('body'), @xml.css('other').first ) ).to be_nil
    end

  end

  describe "#text_after" do

    before do
      @xml = x(<<-EOX.strip_heredoc
             <root>
             <body> <a>A</a> <b>B</b> <c> C </c> <d>D</d> <e>E</e> </body>
             <other />
             </root>
      EOX
      )
    end

    it "should return the text before the node" do
      expect( subject.text_after( @xml.css('body'), @xml.css('c').first ) ).to eq(' D E')
    end

    it "it should return '' if for the first node" do
      expect( subject.text_after( @xml.css('body'), @xml.css('e').first ) ).to eq('')
    end

    it "it should return nil if node is not found" do
      expect( subject.text_after( @xml.css('body'), @xml.css('other').first ) ).to be_nil
    end

  end

  describe "traversal" do

    before do
      @xml = x(<<-EOX.strip_heredoc
             <root>
             <a/>
             <b>
               <c><d/></c>
             </b>
             <e/>
             </root>
      EOX
      )
    end

    it "should traverse depth first" do
      result = []
      subject.depth_traverse(@xml) do |n|
        result << n.name if n.element?
      end

      expect(result).to eq(['a','d','c','b','e','root'])
    end

    it "should traverse breadth first" do
      result = []
      subject.breadth_traverse(@xml) do |n|
        result << n.name if n.element?
      end

      expect(result).to eq(['root','a','b','c','d','e'])
    end

    it "should find the nearest node" do
      d = @xml.css('d').first
      b = @xml.css('b').first

      expect(subject.nearest(d, ['b','root'])).to eq(b)
    end

    it "return nil if there is no nearest node" do
      d = @xml.css('d').first

      expect(subject.nearest(d, ['x-b','x-root'])).to be_nil
    end

  end

end
