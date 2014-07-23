module Id
  class Arxiv < Base
    # cf http://arxiv.org/help/arxiv_identifier

    # yymm.nnnn(Vn)
    NEW_ARXIV_REGEX = '\d{4}\.?\d{4,5}(v\d{1,3})?'
    # subject/yymmnnn - subject can be alpha & . or -
    OLD_ARXIV_REGEX = '[a-z0-9.-]+\/\d{7}'

    NEW_URL_REGEX    = /arxiv\.org\/abs\/(?<result>#{NEW_ARXIV_REGEX})\b/io
    OLD_URL_REGEX    = /arxiv\.org\/abs\/(?<result>#{OLD_ARXIV_REGEX})\b/io
    NEW_PREFIX_REGEX = /\barxiv(\s*id)?:?\s*(?<result>#{NEW_ARXIV_REGEX})\b/io
    OLD_PREFIX_REGEX = /\barxiv(\s*id)?:?\s*(?<result>#{OLD_ARXIV_REGEX})\b/io

    NEW_ID_REGEX    = /\A#{NEW_ARXIV_REGEX}\z/io
    OLD_ID_REGEX    = /\A#{OLD_ARXIV_REGEX}\z/io

    def self.extract(text)
      normalize( match_regexes(text, NEW_URL_REGEX     => true,
                                     OLD_URL_REGEX     => true,
                                     NEW_PREFIX_REGEX  => false,
                                     OLD_PREFIX_REGEX  => false
      ) )
    end

    def self.id(text)
      if text && (text =~ NEW_ID_REGEX || text =~ OLD_ID_REGEX)
        normalize(text)
      else
        nil
      end
    end
    def self.is_id?(text); id(text); end

    def self.normalize(id)
      id = id.try(:strip)
      if id.blank?
        nil
      elsif id =~ /\d{8}/
        id.insert(4,'.')
      else
        id
      end
    end

  end
end