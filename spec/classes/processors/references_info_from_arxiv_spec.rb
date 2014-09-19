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

require 'spec_helper'

describe Processors::ReferencesInfoFromArxiv do
  include Spec::ProcessorHelper

  it "should call the API" do
    refs 'First', 'Second', 'Third'
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { uri_type: :arxiv, uri:'1111.1111' },
                                                              'ref-2' => { },
                                                              'ref-3' => { uri_type: :arxiv, uri:'2222.2222' })

    expect(HttpUtilities).to receive(:post).with("http://export.arxiv.org/api/query?max_results=1000",
                                                 'id_list=1111.1111,2222.2222',
                                                 'Accept'=>Mime::ATOM, 'Content-Type' => Mime::URL_ENCODED_FORM).and_return('{}')

    process
  end

  before do
    refs 'First'
  end

  def reference
    result[:references].first
  end
  def ref_info
    reference[:bibliographic]
  end

  def test_response(arxiv='1111.1111', xml='')
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <feed xmlns="http://www.w3.org/2005/Atom">
      <entry>
        <id>http://arxiv.org/abs/#{arxiv}v2</id>
        #{xml}
      </entry>
    </feed>
  XML
  end

  sample_response = <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <feed xmlns="http://www.w3.org/2005/Atom">
      <link href="http://arxiv.org/api/query?search_query%3D%26id_list%3D1404.1899%26start%3D0%26max_results%3D10" rel="self" type="application/atom+xml"/>
      <title type="html">ArXiv Query: search_query=&amp;id_list=1404.1899&amp;start=0&amp;max_results=10</title>
      <id>http://arxiv.org/api/yvWgBuzbNfRf96TjXxo+ZrIHUK0</id>
      <updated>2014-07-24T00:00:00-04:00</updated>
      <opensearch:totalResults xmlns:opensearch="http://a9.com/-/spec/opensearch/1.1/">1</opensearch:totalResults>
      <opensearch:startIndex xmlns:opensearch="http://a9.com/-/spec/opensearch/1.1/">0</opensearch:startIndex>
      <opensearch:itemsPerPage xmlns:opensearch="http://a9.com/-/spec/opensearch/1.1/">10</opensearch:itemsPerPage>
      <entry>
        <id>http://arxiv.org/abs/1404.1899v2</id>
        <updated>2014-06-12T17:40:30Z</updated>
        <published>2014-04-07T19:31:58Z</published>
        <title>Fingerprints of Galactic Loop I on the Cosmic Microwave Background</title>
        <summary>  Abstract Text.
        </summary>
        <author>
          <name>Hao Liu</name>
          <arxiv:affiliation xmlns:arxiv="http://arxiv.org/schemas/atom">NBI Copenhagen</arxiv:affiliation>
        </author>
        <author>
          <name>Philipp Mertsch</name>
          <arxiv:affiliation xmlns:arxiv="http://arxiv.org/schemas/atom">KIPAC Stanford</arxiv:affiliation>
        </author>
        <author>
          <name>Subir Sarkar</name>
          <arxiv:affiliation xmlns:arxiv="http://arxiv.org/schemas/atom">NBI Copenhagen and U. Oxford</arxiv:affiliation>
        </author>
        <arxiv:doi xmlns:arxiv="http://arxiv.org/schemas/atom">10.1088/2041-8205/789/2/L29</arxiv:doi>
        <link title="doi" href="http://dx.doi.org/10.1088/2041-8205/789/2/L29" rel="related"/>
        <arxiv:comment xmlns:arxiv="http://arxiv.org/schemas/atom">5 pages, 4 figures; small changes and additions (e.g. BICEP2 region
          now shown in Fig.1); accepted for publication in Astrophys. J. Lett</arxiv:comment>
        <arxiv:journal_ref xmlns:arxiv="http://arxiv.org/schemas/atom">Astrophys. J. 789 (2014) L29</arxiv:journal_ref>
        <link href="http://arxiv.org/abs/1404.1899v2" rel="alternate" type="text/html"/>
        <link title="pdf" href="http://arxiv.org/pdf/1404.1899v2" rel="related" type="application/pdf"/>
        <arxiv:primary_category xmlns:arxiv="http://arxiv.org/schemas/atom" term="astro-ph.CO" scheme="http://arxiv.org/schemas/atom"/>
        <category term="astro-ph.CO" scheme="http://arxiv.org/schemas/atom"/>
        <category term="astro-ph.GA" scheme="http://arxiv.org/schemas/atom"/>
      </entry>
    </feed>
  XML

  it "should not call the API if there are cached results" do
    expect(HttpUtilities).to_not receive(:post)

    cached = { references: [
        {id:'ref-1', uri_type: :arxiv, uri:'1234.5678', bibliographic:{bib_source:'cached', title:'cached title'} },
    ] }
    process(cached)

    expect(ref_info[:bib_source]).to eq('cached')
    expect(ref_info[:title] ).to eq('cached title')
  end

  it "should merge in the API results" do
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { uri_type: :arxiv, uri:'1404.1899', score:1.23, uri_source:'test' } )

    expect(HttpUtilities).to receive(:post).and_return(sample_response)

    expect(ref_info).to eq({
                              bib_source:          "arXiv",
                              ARXIV:               '1404.1899',
                              ARXIV_VER:           '1404.1899v2',
                              DOI:                 "10.1088/2041-8205/789/2/L29",
                              abstract:            "Abstract Text.",
                              author:               [{:literal=>"Hao Liu", :affiliation=>"NBI Copenhagen"},
                                                     {:literal=>"Philipp Mertsch", :affiliation=>"KIPAC Stanford"},
                                                     {:literal=>"Subir Sarkar", :affiliation=>"NBI Copenhagen and U. Oxford"}],
                              :"container-title"=> "Astrophys. J. 789 (2014) L29",
                              issued:              [[2014, 4, 7]],
                              subject:             ["astro-ph.CO", "astro-ph.GA"],
                              title:               "Fingerprints of Galactic Loop I on the Cosmic Microwave Background",
                              URL:                 "http://arxiv.org/pdf/1404.1899v2",
                          })
  end

  it "should merge in the API results for a versioned arxiv document" do
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { uri_type: :arxiv, uri:'1404.1899v2', score:1.23, uri_source:'test' } )

    expect(HttpUtilities).to receive(:post).and_return(sample_response)

    expect(ref_info).to include({
                               bib_source:          "arXiv",
                               ARXIV:               '1404.1899',
                               ARXIV_VER:           '1404.1899v2',
                           })
  end

  it "shouldn't fail for any missing data" do
    response = '<feed><entry></entry></feed>'

    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { uri_type: :arxiv, uri:'1404.1899' } )

    expect(HttpUtilities).to receive(:post).and_return(response)

    expect(reference).to eq( uri:'1404.1899', uri_type: :arxiv, number:1, id:'ref-1')
  end

  it "shouldn't fail if there is no data" do
    response = '<feed></feed>'

    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { uri_type: :arxiv, uri:'1404.1899' } )

    expect(HttpUtilities).to receive(:post).and_return(response)

    expect(reference).to eq( uri:'1404.1899', uri_type: :arxiv, number:1, id:'ref-1')
  end

  it "should handle missing results" do
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { uri_type: :arxiv, uri:'1404.1899', attribute:1.23, uri_source:'test' } )

    expect(HttpUtilities).to receive(:post).and_return('{}')

    expect(ref_info).to eq({
                                attribute: 1.23
                            })
  end

  it "should match multiple results even if they are out of order" do
    multiple_response = <<-XML
      <feed>
        <entry>
          <id>http://arxiv.org/abs/2222.2222</id>
        </entry>
        <entry>
          <id>http://arxiv.org/abs/1111.1111</id>
        </entry>
      </feed>
   XML

    refs 'First', 'Second'
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { uri_type: :arxiv, uri:'1111.1111'},
                                                              'ref-2' => { uri_type: :arxiv, uri:'2222.2222'}  )

    expect(HttpUtilities).to receive(:post).and_return(multiple_response)

    expect(result[:references].first[:bibliographic]).to eq({
                                                          bib_source:  'arXiv',
                                                          ARXIV:       '1111.1111',
                                                          ARXIV_VER:    '1111.1111',
                                                      })
    expect(result[:references].second[:bibliographic]).to eq({
                                                          bib_source:  'arXiv',
                                                          ARXIV:       '2222.2222',
                                                          ARXIV_VER:   '2222.2222',
                                                      })
  end

  it "should set the bib_source" do
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { uri_type: :arxiv, uri:'1404.1899', score:1.23, uri_source:'test' } )

    expect(HttpUtilities).to receive(:post).and_return(sample_response)

    expect(ref_info[:bib_source]).to eq('arXiv')
  end

  it "should include different types of authors" do
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { uri_type: :arxiv, uri:'1111.1111' } )

    expect(HttpUtilities).to receive(:post).and_return(test_response('1111.1111', <<-XML))
        <!-- Author -->
        <author>
          <name>Philipp Mertsch</name>
        </author>
        <!-- With affiliation -->
        <author>
          <name>Subir Sarkar</name>
          <arxiv:affiliation xmlns:arxiv="http://arxiv.org/schemas/atom">NBI Copenhagen and U. Oxford</arxiv:affiliation>
        </author>
    XML

    expect(ref_info[:author]).to eq([
                                        {:literal=>"Philipp Mertsch"},
                                        {:literal=>"Subir Sarkar", :affiliation=>"NBI Copenhagen and U. Oxford"},
                                    ])

  end

  it "should include subjects" do
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { uri_type: :arxiv, uri:'1111.1111' } )

    expect(HttpUtilities).to receive(:post).and_return(test_response('1111.1111', <<-XML))
        <arxiv:primary_category xmlns:arxiv="http://arxiv.org/schemas/atom" term="astro-ph.CO" scheme="http://arxiv.org/schemas/atom"/>
        <category term="astro-ph.CO" scheme="http://arxiv.org/schemas/atom"/>
        <category term="astro-ph.GA" scheme="http://arxiv.org/schemas/atom"/>
    XML

    expect(ref_info[:subject]).to eq([ "astro-ph.CO", "astro-ph.GA" ] )
  end

  it "should include markup in the title" do
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { uri_type: :arxiv, uri:'1111.1111' } )

    expect(HttpUtilities).to receive(:post).and_return(test_response('1111.1111', <<-XML))
      <title>
         <p>Title with <i>markup</i>.</p>
      </title
    XML

    expect(ref_info[:title]).to eq('Title with <em>markup</em>.')
  end

  it "should include markup in the abstract" do
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { uri_type: :arxiv, uri:'1111.1111' } )

    expect(HttpUtilities).to receive(:post).and_return(test_response('1111.1111', <<-XML))
      <summary>
      <p>With <i>Markup</i>.</p>
      </summary>
    XML

    expect(ref_info[:abstract]).to eq('With <em>Markup</em>.')
  end

end
