require 'spec_helper'

describe Processors::ReferencesInfoFromIsbn do
  include Spec::ProcessorHelper

  it "should call the API" do
    refs 'First', 'Secpmd', 'Third'
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :isbn, id:'1111111111' },
                                                              'ref-2' => { source:'none'},
                                                              'ref-3' => { id_type: :isbn, id:'2222222222' })

    expect(HttpUtilities).to receive(:get).with('http://openlibrary.org/api/books?format=json&jscmd=data&bibkeys=ISBN:1111111111,ISBN:2222222222', anything).and_return('{}')

    process
  end

  complete_response = <<-JSON
    {
       "ISBN:0451526538":
       {
           "publishers":
           [
               {
                   "name": "Signet Classic"
               }
           ],
           "pagination": "xxi, 216 p. ;",
           "identifiers":
           {
               "lccn":
               [
                   "96072233"
               ],
               "openlibrary":
               [
                   "OL1017798M"
               ],
               "isbn_10":
               [
                   "0451526538"
               ],
               "oclc":
               [
                   "36792831"
               ],
               "librarything":
               [
                   "2236"
               ],
               "project_gutenberg":
               [
                   "74"
               ],
               "goodreads":
               [
                   "1929684"
               ]
           },
           "classifications":
           {
               "dewey_decimal_class":
               [
                   "813/.4"
               ],
               "lc_classifications":
               [
                   "PS1306 .A1 1997"
               ]
           },
           "title": "The adventures of Tom Sawyer",
           "subtitle": "how financial models shape markets",
           "url": "https://openlibrary.org/books/OL1017798M/The_adventures_of_Tom_Sawyer",
           "notes": "Includes bibliographical references (p. 213-216).",
           "number_of_pages": 216,
           "cover":
           {
               "small": "https://covers.openlibrary.org/b/id/295577-S.jpg",
               "large": "https://covers.openlibrary.org/b/id/295577-L.jpg",
               "medium": "https://covers.openlibrary.org/b/id/295577-M.jpg"
           },
           "subject_places":
           [
               {
                   "url": "https://openlibrary.org/subjects/place:missouri",
                   "name": "Missouri"
               },
               {
                   "url": "https://openlibrary.org/subjects/place:mississippi_river",
                   "name": "Mississippi River"
               }
           ],
           "subjects":
           [
               {
                   "url": "https://openlibrary.org/subjects/fiction",
                   "name": "Fiction"
               },
               {
                   "url": "https://openlibrary.org/subjects/mississippi_river",
                   "name": "Mississippi River"
               }
           ],
           "subject_people":
           [
               {
                   "url": "https://openlibrary.org/subjects/person:mark_twain_(1835-1910)",
                   "name": "Mark Twain (1835-1910)"
               }
           ],
           "key": "/books/OL1017798M",
           "authors":
           [
               {
                   "url": "https://openlibrary.org/authors/OL18319A/Mark_Twain",
                   "name": "Mark Twain"
               }
           ],
           "publish_date": "1997",
           "by_statement": "Mark Twain ; with an introduction by Robert S. Tilton.",
           "publish_places":
           [
               {
                   "name": "New York"
               }
           ],
           "subject_times":
           [
               {
                   "url": "https://openlibrary.org/subjects/time:19th_century",
                   "name": "19th century"
               }
           ]
       }
    }
  JSON

  it "should not call the API if there are cached results" do
    refs 'First'
    expect(HttpUtilities).to_not receive(:get)

    cached = { references: {
        'ref-1' => { id_type: :isbn, id:'1234567890', info:{source:'cached', title:'cached title'} },
    } }
    process(cached)

    expect(result[:references]['ref-1'][:info][:source]).to eq('cached')
    expect(result[:references]['ref-1'][:info][:title] ).to eq('cached title')
  end

  it "should merge in the API results" do
    refs 'First'
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :isbn, id:'0451526538', score:1.23, ref_source:'test' } )

    expect(HttpUtilities).to receive(:get).and_return(complete_response)

    expect(result[:references]['ref-1'][:info]).to eq({
                                                          ref_source: 'test',
                                                          id:         '0451526538',
                                                          id_type:    :isbn,
                                                          score:      1.23,
                                                          source:     "OpenLibrary",
                                                          key:        "/books/OL1017798M",
                                                          ISBN:       ["0451526538"],
                                                          OCLC:       ["36792831"],
                                                          OLID:       ["OL1017798M"],
                                                          URL:        "https://openlibrary.org/books/OL1017798M/The_adventures_of_Tom_Sawyer",
                                                          authors:    [[{:literal=>"Mark Twain"}]],
                                                          cover:      "https://covers.openlibrary.org/b/id/295577-S.jpg",
                                                          issued:     "1997",
                                                          pages:      216,
                                                          publisher:  "Signet Classic",
                                                          title:      "The adventures of Tom Sawyer",
                                                          subtitle:   ["how financial models shape markets"],
                                                          subject:    ["Fiction", "Mississippi River", "Missouri", "Mark Twain (1835-1910)", "19th century"],
                                                      })
  end

  it "shouldn't fail for any missing data" do
    response = '{ "ISBN:1111111111": {} }'

    refs 'First'
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :isbn, id:'1111111111' } )

    expect(HttpUtilities).to receive(:get).and_return(response)

    expect(result[:references]['ref-1'][:info]).to eq( id:'1111111111', id_type: :isbn, source:'OpenLibrary')
  end

  it "should handle missing results" do
    refs 'First'
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :isbn, id:'0451526538', score:1.23, ref_source:'test' } )

    expect(HttpUtilities).to receive(:get).and_return('{}')

    expect(result[:references]['ref-1'][:info]).to eq({
                                                          ref_source: 'test',
                                                          id:         '0451526538',
                                                          id_type:    :isbn,
                                                          score:      1.23
                                                      })
  end

  it "should match multiple results even if they are out of order" do
    multiple_response = <<-JSON
    {
       "ISBN:2222222222": { "key": "/books/OL02" },
       "ISBN:1111111111": { "key": "/books/OL01" }
    }
    JSON

    refs 'First', 'Second'
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :isbn, id:'1111111111'},
                                                              'ref-2' => { id_type: :isbn, id:'2222222222'}  )

    expect(HttpUtilities).to receive(:get).and_return(multiple_response)

    expect(result[:references]['ref-1'][:info]).to eq({
                                                          id:         '1111111111',
                                                          id_type:    :isbn,
                                                          source:     'OpenLibrary',
                                                          key:        '/books/OL01'
                                                      })
    expect(result[:references]['ref-2'][:info]).to eq({
                                                          id:         '2222222222',
                                                          id_type:    :isbn,
                                                          source:     'OpenLibrary',
                                                          key:        '/books/OL02'
                                                      })
  end

  it "should not overwrite the type, id, score or ref_source" do
    refs 'First'
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :isbn, id:'0451526538', score:1.23, ref_source:'test' } )

    expect(HttpUtilities).to receive(:get).and_return(complete_response)

    expect(result[:references]['ref-1'][:info]).to include(
                                                          id_type:     :isbn,
                                                          id:          '0451526538',
                                                          ref_source:  'test',
                                                          score:       1.23
                                                      )
  end

end
