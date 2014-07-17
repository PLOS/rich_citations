require 'spec_helper'

describe IdentifierResolvers::PubmedidFromReference do

  context "Interface" do

    it "should have a resolve method" do
      resolver = described_class.new(:root, :refs)
      expect(resolver).to  respond_to(:resolve)
    end

  end

  context "Parsing Pubmed ID" do

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
          <comment>Pubmed ID:<a>1234567890</a></comment>
        </ref>
      XML

      expect(resolver).to receive(:set_result).with('ref-1', ref_source: :ref, id:'1234567890', id_type: :pmid)
      resolver.resolve
    end

  end

end