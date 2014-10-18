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

module IdentifierResolvers
  class CrossRef < Base
    SLICE_SIZE=50
    
    # cf  http://search.crossref.org/help/api#match
    API_URL = 'http://search.crossref.org/links'
    # secret URL
    #API_URL = 'http://148.251.178.33/links'
    
    def resolve
      unresolved_texts = unresolved_references.map { |id, data|
        parsed = CrossRef.parse_ref_journal(data.node)
        text = CrossRef.format_for_crossref(parsed)
        text = data.text if text.blank?
        [id, text]
      }.to_h
      @crossref_infos = state[:crossref_infos] = {}
      unresolved_texts.each_slice(SLICE_SIZE) do |group|
        # if it failed, try each individual item
        if !resolve_group(group.to_h) then
          group.each do |r|
            resolve_group([r].to_h)
          end
        end
        sleep(2)
      end
    end

    private

    def self.parse_ref_journal(ref)
      data = {}
      names = []
      ref.xpath('.//name').each do |name_node|
        name = {}
        # get surname and given-names
        surname_text = name_node.xpath('surname').text
        name['surname'] = surname_text unless surname_text.blank?
        given_names_text = name_node.xpath('given-names').text
        name['given-names'] = given_names_text unless given_names_text.blank?
        names.append(name)
      end
      ref.xpath('.//collab').each do |name_node|
        names.append('collab' => name_node.text)
      end
      data['names'] = names

      ['article-title', 'source', 'volume', 'issue', 'fpage',
       'lpage', 'elocation-id', 'year'].each do |n|
        txt = ref.xpath(".//#{n}").text
        data[n] = txt unless txt.blank?
      end
      data
    end

    def self.format_for_crossref(ref_data)
      # https://github.com/PLOS/developer-scripts/blob/master/citedArticle/populateCitationDoiFromCrossRef.py
      crossref_data = ''
      names = []
      ref_data['names'].each do |name|
        name_data = ''
        if (name.key?('surname') && name.key?('given-names'))
          surname = name['surname']
          given_name = name['given-names']
          if (given_name.match(/\p{Upper}/))
            # format the given name Example: J. or J. D.
            name_data = given_name.split(//).map { |c| "#{c}." }.join(' ') + ' ' + surname
          else
            # assuming that this is a full given name
            name_data = given_name + ' ' + surname
          end
        elsif name.key?('surname')
          name_data = name['surname']
        elsif name.key?('collab')
          name_data = name['collab']
        end
        names.append(name_data) unless name_data.blank?
        crossref_data = names.join(', ')
      end
      crossref_data << ", \"#{ref_data['article-title']}\"" if (ref_data.key?('article-title'))
      crossref_data << ", #{ref_data['source']}" if ref_data.key?('source')
      crossref_data << ", vol. #{ref_data['volume']}" if ref_data.key?('volume')
      crossref_data << ", no. #{ref_data['issue']}" if ref_data.key?('issue')
      if ref_data.key?('fpage')
        crossref_data << ", pp. #{ref_data['fpage']}"
        crossref_data << "-#{ref_data['lpage']}" if ref_data.key?('lpage')
      end
      crossref_data << ", e#{ref_data['elocation-id']}" if ref_data.key?('elocation-id')
      crossref_data << ", #{ref_data['year']}" if ref_data.key?('year')
      crossref_data
    end

    # Results with a lower score from the crossref.org will be ignored
    MIN_CROSSREF_SCORE = 2.5 #@TODO: Keeping this value high to force skips for testing

    def resolve_group(references)
      texts    = JSON.generate( references.values )
      response = HttpUtilities.post(API_URL, texts,
                                    { 'Accept' => Mime::XML.to_s,
                                      'Content-Type' => Mime::JSON.to_s })
      response_json = JSON.parse(response)
      if (!response_json['query_ok']) then
        return false
      else
        results  = response_json['results']
        results.each_with_index do |result, i|
          id    = references.keys[i]
          info  = extract_info(result)
          next unless info
          
          @crossref_infos[id] = info
          set_result(id, info) if include_info?(info)
        end
        return true
      end
    end

    def include_info?(info)
      info && info[:score] && info[:score] >= MIN_CROSSREF_SCORE
    end

    def extract_info(result)
      self.class.extract_info(result)
    end

    def self.extract_info(result)
      return nil unless result['match']
      doi = Id::Doi.extract( result['doi'] )
      return nil unless doi.present?

      {
        uri_source:   :crossref,
        uri_type:     :doi,
        uri:          "http://dx.doi.org/#{doi}",
        score:        result['score'].to_f,
      }
    end

  end
end
