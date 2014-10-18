# Copyright (c) 2014 Public Library of Science

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'uri'

module Processors
  class ReferencesInfoFromWikipedia < Base
    include Helpers

    def process
      references = references_without_bib_info(:wikipedia)
      fill_info_for_references( references ) if references.present?
    end

    def self.dependencies
      ReferencesInfoCacheLoader
    end

    #@todo set appropriate user agent header #@mro

    API_URL = "http://%{lang}.wikipedia.org/w/index.php?title=Special:CiteThisPage&page=%{page}"

    # map of Wikipedia COINS keys to Rich Citations keys
    def coins_map                            # e.g.:
      { 'rft.type'        =>  'type',        # 'encyclopediaArticle',
        'rft.title'       =>  'title',       # 'Jean_Tirole',
        'rft.date'        =>  'issued',      # '2014-12-22',
        'rft.source'      =>  'bib_source',  # 'Wikipedia, The Free Encyclopedia',
        'rft.aucorp'      =>  'author',      # 'Wikipedia contributors',
        'rft.publisher'   =>  'publisher',   # 'Wikimedia Foundation',
        #'rft.artnum'     =>  '',            # '639251292',
        'rft.identifier'  =>  'URL',         # 'http://en.wikipedia.org/w/index.php?title=Jean_Tirole&oldid=639251292',
        'rft.language'    =>  'language',    # 'en',
        #'rft.format'     =>  '',            # 'text',
        'rft.rights'      =>  'license',     # 'CC-BY-SA 3.0'
      }
    end
    # must meet these key->val constraints or the
    # map may be incorrect
    def coins_constraints
      { 'ctx_ver'     => 'Z39.88-2004',
        'rft_val_fmt' => 'info:ofi/fmt:kev:mtx:dc',
        'rfr_id'      => 'info:sid/en.wikipedia.org:article'
      }
    end

    def fill_info_for_references(references)
      references.each do |ref|
        parts = Id::Wikipedia.match_url_parts(ref[:uri])
        page = parts[:page]
        next unless page.present?

        coins_data = fetch_results_for_page(page, parts[:language])
        return unless coins_data.present?

        ref[:bibliographic].merge!(coins_data)
      end
    end

    def fetch_results_for_page(page,lang='en')
      html = HttpUtilities.get(API_URL % {:page => page, :lang => lang})
      doc = Loofah.document(html)
      return ReferencesInfoFromCoins.extract_coins(doc,coins_map,coins_constraints)
    end

  end

end
