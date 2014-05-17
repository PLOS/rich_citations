module Spec
  module XmlBuilder

    def parts
      @parts ||= {}
    end

    def doi(doi)
      parts[:doi] = doi
    end

    def refs(*refs)
      (parts[:refs] ||= []).concat(refs)
    end

    def meta (meta)
      (parts[:meta] ||= '') << meta
    end

    def body (body)
      (parts[:body] ||= '') << body
    end

    def cite(number)
      "<xref ref-type='bibr' rid='ref-#{number}'>[#{number}]</xref>"
    end

    def ref_list
      if parts[:refs]
        parts[:refs].map.with_index{ |r,i| "<ref id='ref-#{i+1}'>#{r}</ref>" }.join
      end
    end

    def xml
      xml = <<-EOS
        <root>
          <article-id pub-id-type='doi'>#{parts[:doi] || '10.12345/1234.12345'}</article-id>
          <article-meta>#{parts[:meta]}</article-meta>
          <body>#{parts[:body]}</body>
          <ref-list>#{ref_list}</ref-list>
        </root>
      EOS

      Nokogiri.XML(xml)
    end

  end
end