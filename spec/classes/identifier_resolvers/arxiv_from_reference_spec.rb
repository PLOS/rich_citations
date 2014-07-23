require 'spec_helper'

describe IdentifierResolvers::ArxivFromReference do

  context "Interface" do

    it "should have a resolve method" do
      resolver = described_class.new(:root, :refs)
      expect(resolver).to  respond_to(:resolve)
    end

  end

  context "Parsing Arxiv IDs" do

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
          <comment>arxiv:<a>1234.5678</a></comment>
        </ref>
      XML

      expect(resolver).to receive(:set_result).with('ref-1', id_source: :ref, id:'1234.5678', id_type: :arxiv)
      resolver.resolve
    end

    it "should resolve from XML" do
      resolver = make_resolver <<-XML
        <ref id="ref-1">
          <comment><elem attr="http://arxiv.org/abs/1234.5678" /></comment>
        </ref>
      XML

      expect(resolver).to receive(:set_result).with('ref-1', id_source: :ref, id:'1234.5678', id_type: :arxiv)
      resolver.resolve
    end

    context "When the source attribute contains /arxiv/" do

      it "should resolve from the volume" do
        resolver = make_resolver <<-XML
          <ref id="ref-1">
            <source>Arxiv preprint</source>
            <volume>12345678</volume>
          </ref>
        XML

        expect(resolver).to receive(:set_result).with('ref-1', id_source: :ref, id:'1234.5678', id_type: :arxiv)
        resolver.resolve
      end

      it "should resolve from the fpage" do
        resolver = make_resolver <<-XML
          <ref id="ref-1">
            <source>Arxiv preprint</source>
            <fpage>12345678</fpage>
          </ref>
        XML

        expect(resolver).to receive(:set_result).with('ref-1', id_source: :ref, id:'1234.5678', id_type: :arxiv)
        resolver.resolve
      end

      it "should resolve from the volume and fpage" do
        resolver = make_resolver <<-XML
          <ref id="ref-1">
            <source>Arxiv preprint</source>
            <volume>1234</volume>
            <fpage>5678</fpage>
          </ref>
        XML

        expect(resolver).to receive(:set_result).with('ref-1', id_source: :ref, id:'1234.5678', id_type: :arxiv)
        resolver.resolve
      end

    end

  end

end