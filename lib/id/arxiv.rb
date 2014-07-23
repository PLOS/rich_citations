module Id
  class Arxiv < Base
    # cf http://arxiv.org/help/arxiv_identifier

    # yymm.nnnn(Vn)
    NEW_ARXIV_REGEX = '\d{4}\.\d{4,5}(v\d{1,3})?'
    # subject/yymmnnn - subject can be alpha & . or -
    OLD_ARXIV_REGEX = '[a-z0-9.-]+\/\d{7}'

    NEW_URL_REGEX    = /arxiv\.org\/abs\/(?<result>#{NEW_ARXIV_REGEX})\b/io
    OLD_URL_REGEX    = /arxiv\.org\/abs\/(?<result>#{OLD_ARXIV_REGEX})\b/io
    NEW_PREFIX_REGEX = /\barxiv:?\s*(?<result>#{NEW_ARXIV_REGEX})\b/io
    OLD_PREFIX_REGEX = /\barxiv:?\s*(?<result>#{OLD_ARXIV_REGEX})\b/io

    def self.extract(text)
      normalize( match_regexes(text, NEW_URL_REGEX     => true,
                                     OLD_URL_REGEX     => true,
                                     NEW_PREFIX_REGEX  => false,
                                     OLD_PREFIX_REGEX  => false
      ) )
    end

  end
end