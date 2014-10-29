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

class PaperResult < ActiveRecord::Base

  INGEST_BASE_URL = 'http://api.richcitations.org/papers'

  validates :doi, presence:true

  def self.find_by_doi(doi)
    self.where(doi:doi).first
  end

  def self.find_by_doi!(doi)
    self.where(doi:doi).first!
  end

  def self.find_or_new_for_doi(doi)
    params = { doi:doi }
    self.where(params).first || self.new(params)
  end

  def self.calculate_for(doi)
    result = find_by_doi(doi)
    if result && result.ready?
      Rails.logger.info("Using cached #{doi}")
      result.touch
      return result
    end

    Rails.logger.info("Fetching #{doi} ...")
    xml = Plos::Api.document( doi )
    Rails.logger.info("Parsing #{doi} ...")
    info = PaperParser.parse_xml(xml)

    result = find_by_doi(doi) || new(doi:doi)
    result.info_json = JSON.generate(info)
    result.save!

    result
  end

  def bibliographic
    @bibliographic ||= ready? ? JSON.parse(info_json).symbolize_keys_recursive! : nil
  end
  alias result bibliographic

  def should_start_analysis?
    !ready? && ( new_record? || timed_out?)
  end

  def start_analysis!
    if ready?
      self.touch

    else
      # Note this does not prevent a task being started multiple times
      ThreadingHelpers.background("Analyze PaperResult:#{self.id}") do
        analyze!
      end

    end

  end

  def ready?
    info_json.present?
  end

  def self.journal_url(doi)
    case doi
    when /journal\.pone/
      "http://www.plosone.org"
    when /journal\.pbio/
      "http://www.plosbiology.org"
    when /journal\.pmed/
      "http://www.plosmedicine.org"
    when /journal\.pgen/
      "http://www.plosgenetics.org"
    when /journal\.pcbi/
      "http://www.ploscompbiol.org"
    when /journal\.ppat/
      "http://www.plospathogens.org"
    when /journal\.pntd/
      "http://www.plosntds.org"
    when /journal\.pctr/
      "http://www.plosclinicaltrials.org/"
    when /eLife/
      'http://elifesciences.org/content/elife/3'
    when /peerj/
      'https://peerj.com/'
    else
      raise Exception.new("Unknown journal found in #{doi}")
    end
  end

  private

  def analyze!
    if ready?
      Rails.logger.info("Using cached #{doi}")
      touch
    end

    Rails.logger.info("Fetching #{doi} ...")
    xml = Plos::Api.document( doi )
    Rails.logger.info("Parsing #{doi} ...")
    info = PaperParser.parse_xml(xml)

    self.info_json = JSON.generate(info)
    self.save!
    ingest
  end

  # ingest into read/write API
  def ingest
    json = self.result.deep_dup.with_indifferent_access
    JsonUtilities.strip_uri_type!(json)
    JsonUtilities.clean_uris!(json)
    client = HTTPClient.new
    doi_uri = "http://dx.doi.org/#{URI.encode_www_form_component(doi)}"
    return if (client.head(INGEST_BASE_URL, uri: doi_uri).status == 200)
    client.post("#{INGEST_BASE_URL}?api_key=#{ENV['RC_API_KEY']}&uri=#{URI.encode_www_form_component(doi_uri)}",
                MultiJson.dump(json),
                'Content-Type' => 'application/json',
                'Accept' => 'application/json')
  end

  def timed_out?
    Time.now - updated_at > 2.minutes
  end
end
