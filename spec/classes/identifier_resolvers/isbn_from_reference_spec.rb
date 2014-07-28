require 'spec_helper'

describe IdentifierResolvers::IsbnFromReference do

  context "Interface" do

    it "should have a resolve method" do
      resolver = described_class.new(:root, :refs)
      expect(resolver).to  respond_to(:resolve)
    end

  end

  context "Parsing ISBN" do

    def make_resolver(node)
      node = Nokogiri::XML(node)
      id   = node.at_css('ref').attr('id')

      ref = Hashie::Mash.new(
          id:   id,
          node: node,
          text: node.text
      )

      resolver = described_class.new(:root, { id => ref })
    end

    it "should resolve from XML text" do
      resolver = make_resolver <<-XML
        <ref id="ref-1">
          <comment>ISBN:<a>123-4567-89-0</a></comment>
        </ref>
      XML

      expect(resolver).to receive(:set_result).with('ref-1', id_source: :ref, id:'1234567890', id_type: :isbn)
      resolver.resolve
    end

  end

end