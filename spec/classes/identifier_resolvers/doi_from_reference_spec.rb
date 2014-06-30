require 'spec_helper'

describe IdentifierResolvers::DoiFromReference do

  context "Interface" do

    it "should have a resolve method" do
      resolver = described_class.new(:root, :refs)
      expect(resolver).to  respond_to(:resolve)
    end

  end

  context "Parsing DOI" do

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
          <comment>doi:<a>10.1111/1111</a></comment>
        </ref>
      XML

      expect(resolver).to receive(:set_result).with('ref-1', :doi, source: :ref, doi:'10.1111/1111')
      resolver.resolve
    end

    it "should resolve from XML" do
      resolver = make_resolver <<-XML
        <ref id="ref-1">
          <comment><elem attr="http://dx.doi.org/10.1111/1111" /></comment>
        </ref>
      XML

      expect(resolver).to receive(:set_result).with('ref-1', :doi, source: :ref, doi:'10.1111/1111')
      resolver.resolve
    end

    it "should resolve from a link" do
      resolver = make_resolver <<-XML
        <ref id="ref-1">
          <comment><ext-link ext-link-type="doi" xlink:href="http://dx.doi.org/10.1111/1111" xlink:type="simple"></ext-link></comment>
        </ref>
      XML

      expect(resolver).to receive(:set_result).with('ref-1', :doi, source: :ref, doi:'10.1111/1111')
      resolver.resolve
    end

    it "should resolve a link before any other XML" do
      resolver = make_resolver <<-XML
        <ref id="ref-1">
          <comment>
             <ext-link ext-link-type="doi" xlink:href="http://dx.doi.org/10.1111/1111" xlink:type="simple"></ext-link>
             <a href="http://dx.doi.org/10.1111/2222"></a>
          </comment>
        </ref>
      XML

      expect(resolver).to receive(:set_result).with('ref-1', :doi, source: :ref, doi:'10.1111/1111')
      resolver.resolve
    end

    it "should resolve XML before embedded text" do
      resolver = make_resolver <<-XML
        <ref id="ref-1">
          <comment>
             doi: <a href="http://dx.doi.org/10.1111/1111">10.1111/1111</a>
          </comment>
        </ref>
      XML

      expect(resolver).to receive(:set_result).with('ref-1', :doi, source: :ref, doi:'10.1111/1111')
      resolver.resolve
    end

  end

end