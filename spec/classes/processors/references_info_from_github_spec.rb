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

describe Processors::ReferencesInfoFromGithub do
  include Spec::ProcessorHelper

  # it "should call the API" do
  #   refs 'First', 'Second', 'Third'
  #   allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :github, id:'1111.1111' },
  #                                                             'ref-2' => { },
  #                                                             'ref-3' => { id_type: :github, id:'2222.2222' })
  #
  #   expect(HttpUtilities).to receive(:post).with("http://export.arxiv.org/api/query?max_results=1000",
  #                                                'id_list=1111.1111,2222.2222',
  #                                                'Accept'=>Mime::ATOM, 'Content-Type' => Mime::URL_ENCODED_FORM).and_return('{}')
  #
  #   process
  # end

  before do
    refs 'First'
  end

  def ref_info
    result[:references]['ref-1'][:bibliographic]
  end

  it "should not parse the URL if there are cached results" do
    expect(HttpUtilities).to_not receive(:get)

    cached = { references: {
        'ref-1' => { id_type: :github, id:'git@github.com:owner/repo', bibliographic:{info_source:'cached', title:'cached title', URL:'cached url'} },
    } }
    process(cached)

    expect(ref_info[:info_source]).to eq('cached')
    expect(ref_info[:title] ).to eq('cached title')
    expect(ref_info[:URL] ).to eq('cached url')
  end

  it "should merge in the parsed url results" do
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :github, id:'git@github.com:owner/repo', score:1.23, id_source:'test' } )

    allow(HttpUtilities).to receive(:get).and_return({})

    expect(ref_info).to eq({
                              id_source:           'test',
                              id:                  'git@github.com:owner/repo',
                              id_type:             :github,
                              score:               1.23,
                              info_source:         "github",
                              URL:                 'git@github.com:owner/repo',
                              GITHUB_OWNER:        'owner',
                              GITHUB_REPO:         'owner/repo',
                           })
  end

  # it "should not call the API if there are cached results" do
  #   expect(HttpUtilities).to_not receive(:post)
  #
  #   cached = { references: {
  #       'ref-1' => { id_type: :github, id:'git@github.com:owner/repo', bibliographic:{info_source:'cached', title:'cached title'} },
  #   } }
  #   process(cached)
  #
  #   expect(ref_info[:info_source]).to eq('cached')
  #   expect(ref_info[:title] ).to eq('cached title')
  # end

  # it "should merge in the API results" do
  #   allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :github, id:'git@github.com:owner/repo', score:1.23, id_source:'test' } )
  #
  #   expect(HttpUtilities).to receive(:post).and_return(sample_response)
  #
  #   expect(ref_info).to eq({
  #                             id_source:           'test',
  #                             id:                  '1404.1899',
  #                             id_type:             :github,
  #                             score:               1.23,
  #                             info_source:         "github",
  #                             DOI:                 "10.1088/2041-8205/789/2/L29",
  #                             abstract:            "Abstract Text.",
  #                             author:               [{:literal=>"Hao Liu", :affiliation=>"NBI Copenhagen"},
  #                                                    {:literal=>"Philipp Mertsch", :affiliation=>"KIPAC Stanford"},
  #                                                    {:literal=>"Subir Sarkar", :affiliation=>"NBI Copenhagen and U. Oxford"}],
  #                             :"container-title"=> "Astrophys. J. 789 (2014) L29",
  #                             issued:              [[2014, 4, 7]],
  #                             subject:             ["astro-ph.CO", "astro-ph.GA"],
  #                             title:               "Fingerprints of Galactic Loop I on the Cosmic Microwave Background",
  #                             URL:                 "http://arxiv.org/pdf/1404.1899v2",
  #                         })
  # end

  # it "shouldn't fail for any missing data" do
  #   response = '<feed><entry></entry></feed>'
  #
  #   allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :github, id:'git@github.com:owner/repo' } )
  #
  #   expect(HttpUtilities).to receive(:post).and_return(response)
  #
  #   expect(ref_info).to eq( id:'git@github.com:owner/repo', id_type: :github)
  # end

  # it "shouldn't fail if there is no data" do
  #   response = '<feed></feed>'
  #
  #   allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :github, id:'git@github.com:owner/repo' } )
  #
  #   expect(HttpUtilities).to receive(:post).and_return(response)
  #
  #   expect(ref_info).to eq( id:'git@github.com:owner/repo', id_type: :github)
  # end

  # it "should handle missing results" do
  #   allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :github, id'git@github.com:owner/repo', score:1.23, id_source:'test' } )
  #
  #   expect(HttpUtilities).to receive(:post).and_return('{}')
  #
  #   expect(ref_info).to eq({
  #                               id_source:  'test',
  #                               id:         'git@github.com:owner/repo',
  #                               id_type:    :github,
  #                               score:      1.23
  #                           })
  # end

  # it "should not overwrite the type, id, score or id_source" do
  #   allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :github, id:'git@github.com:owner/repo', score:1.23, id_source:'test' } )
  #
  #   expect(HttpUtilities).to receive(:post).and_return(sample_response)
  #
  #   expect(ref_info).to include(
  #                                   id_type:     :github,
  #                                   id:          'git@github.com:owner/repo',
  #                                   id_source:   'test',
  #                                   score:       1.23
  #                               )
  # end

  # it "should include different types of authors" do
  #   allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :github, id:'git@github.com:owner/repo' } )
  #
  #   expect(HttpUtilities).to receive(:post).and_return(test_response('1111.1111', <<-XML))
  #       <!-- Author -->
  #       <author>
  #         <name>Philipp Mertsch</name>
  #       </author>
  #       <!-- With affiliation -->
  #       <author>
  #         <name>Subir Sarkar</name>
  #         <arxiv:affiliation xmlns:arxiv="http://arxiv.org/schemas/atom">NBI Copenhagen and U. Oxford</arxiv:affiliation>
  #       </author>
  #   XML
  #
  #   expect(ref_info[:author]).to eq([
  #                                       {:literal=>"Philipp Mertsch"},
  #                                       {:literal=>"Subir Sarkar", :affiliation=>"NBI Copenhagen and U. Oxford"},
  #                                   ])
  #
  # end

  # it "should include subjects" do
  #   allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :github, id:'git@github.com:owner/repo' } )
  #
  #   expect(HttpUtilities).to receive(:post).and_return(test_response('1111.1111', <<-XML))
  #       <arxiv:primary_category xmlns:arxiv="http://arxiv.org/schemas/atom" term="astro-ph.CO" scheme="http://arxiv.org/schemas/atom"/>
  #       <category term="astro-ph.CO" scheme="http://arxiv.org/schemas/atom"/>
  #       <category term="astro-ph.GA" scheme="http://arxiv.org/schemas/atom"/>
  #   XML
  #
  #   expect(ref_info[:subject]).to eq([ "astro-ph.CO", "astro-ph.GA" ] )
  # end

  # it "should include markup in the title" do
  #   allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :github, id:'git@github.com:owner/repo' } )
  #
  #   expect(HttpUtilities).to receive(:post).and_return(test_response('1111.1111', <<-XML))
  #     <title>
  #        <p>Title with <i>markup</i>.</p>
  #     </title
  #   XML
  #
  #   expect(ref_info[:title]).to eq('Title with <em>markup</em>.')
  # end

  # it "should include markup in the abstract" do
  #   allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :github, id:'git@github.com:owner/repo' } )
  #
  #   expect(HttpUtilities).to receive(:post).and_return(test_response('1111.1111', <<-XML))
  #     <summary>
  #     <p>With <i>Markup</i>.</p>
  #     </summary>
  #   XML
  #
  #   expect(ref_info[:abstract]).to eq('With <em>Markup</em>.')
  # end

end
