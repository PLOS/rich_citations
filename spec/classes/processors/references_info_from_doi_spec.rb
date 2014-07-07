require 'spec_helper'

describe Processors::ReferencesInfoFromDoi do
  include Spec::ProcessorHelper

  it "should call the API" do
    refs 'First', 'Secpmd', 'Third'
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :doi, id:'10.111/111' },
                                                              'ref-2' => { source:'none'},
                                                              'ref-3' => { id_type: :doi, id:'10.333/333' })

    expect(HttpUtilities).to receive(:get).with('http://dx.doi.org/10.111%2F111', anything).and_return('{}')
    expect(HttpUtilities).to receive(:get).with('http://dx.doi.org/10.333%2F333', anything).and_return('{}')

    process
  end

  it "should merge in the API results" do
    refs 'First', 'Secpmd', 'Third'
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :doi, id:'10.111/111', score:1.23, source:'test' } )

    info = {
        author: [ {given:'C.', family:'Theron'} ],
        title:  'A Title',
    }
    expect(HttpUtilities).to receive(:get).with('http://dx.doi.org/10.111%2F111', anything).and_return(JSON.generate(info))

    expect(result[:references]['ref-1'][:info]).to eq({
                                                          id:     '10.111/111',
                                                          id_type: :doi,
                                                          source: 'test',
                                                          score:  1.23,
                                                          author: [ {given:'C.', family:'Theron'} ],
                                                          title:  'A Title',
                                                      })
  end

  it "should not call the API if there are cached results" do
    refs 'First'
    expect(HttpUtilities).to_not receive(:get)

    cached = { references: {
        'ref-1' => { id_type: :doi, id:'10.1371/11111', info:{type:'cached', title:'cached title'} },
    } }
    process(cached)

    expect(result[:references]['ref-1'][:info][:type] ).to eq('cached')
    expect(result[:references]['ref-1'][:info][:title]).to eq('cached title')
  end

  it "should not overwrite the type, id, score or source" do
    refs 'First', 'Secpmd', 'Third'
    allow(IdentifierResolver).to receive(:resolve).and_return('ref-1' => { id_type: :doi, id:'10.111/111', score:1.23, ref_source:'test' } )

    info = {
        id:         '10.xxx/xxx',
        id_type:    :foo,
        score:      99,
        ref_source: 'ignored',
    }
    expect(HttpUtilities).to receive(:get).with('http://dx.doi.org/10.111%2F111', anything).and_return(JSON.generate(info))

    expect(result[:references]['ref-1'][:info]).to eq({
                                                          id_type:     :doi,
                                                          id:          '10.111/111',
                                                          ref_source:  'test',
                                                          score:       1.23,
                                                      })
  end

end
