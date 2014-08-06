# coding: utf-8

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

require "spec_helper"

Capybara.default_wait_time = 60

describe "reference viewing", :type => :feature, :js => true do
  before(:all) do
    WebMock.stub_request(:get, 'www.plosone.org/article/fetchObjectAttachment.action?uri=info:doi/10.1371%2Fjournal.pone.0067380&representation=XML').
      to_return(:status => 200,
                :body   => File.open(File.join(Rails.root, 'fixtures', '10.1371%2Fjournal.pone.0067380.xml')))
#    WebMock.stub_request(:post, "http://search.crossref.org/links").
#      to_return(:status => 200, :body => "", :headers => {})
    
    #      with(#:body => hash_including({:data => ["Clua E , Grosvalet F ( 2000 ) Mixed-species feeding aggregation of dolphins, large tunas and seabirds in the Azores. Aquat. Living Resour . 14 : 11 – 18 ."]}),
    #           :headers => {'Accept'=>'application/xml'}).
  end

  it "should properly sort a references list" do
    visit '/view/10.1371/journal.pone.0067380'
    expect(page.first(:xpath, '//ol[@class="references"]/li/div')['id']).to eq("reference_pone.0067380-Clua1")

    page.click_button("Citation groups")
    expect(page.first(:xpath, '//ol[@class="references"]//ol/li/div')['id']).to eq("reference_pone.0067380-Clua1")

    page.click_button("Year")
    expect(page.first(:xpath, '//ol[@class="references"]/li/div')['id']).to eq("reference_pone.0067380-Sperone2")

    page.click_button("Author")
    expect(page.first(:xpath, '//ol[@class="references"]/li/div')['id']).to eq("reference_pone.0067380-Aalbers1")

    page.click_button("Journal")
    expect(page.first(:xpath, '//ol[@class="references"]//ol/li/div')['id']).to eq("reference_pone.0067380-ODonoghue1")

    page.click_button("Number of appearances")
    expect(page.first(:xpath, '//ol[@class="references"]/li/div')['id']).to eq("reference_pone.0067380-Domenici1")

    page.click_button("Order in paper")
    expect(page.first(:xpath, '//ol[@class="references"]/li/div')['id']).to eq("reference_pone.0067380-Clua1")
  end

  it "should work on an article that has a missing citation" do
    visit '/view/10.1371/journal.pone.0100000'

    page.click_button("Number of appearances")
    expect(page.first(:xpath, '//ol[@class="references"]/li/div')['id']).to eq("reference_pone.0100000-Villa2")
  end    

  it "should display a retracted mark for retracted cites" do
    visit '/view/10.1371/journal.pone.0059428'

    expect(page).to have_content("RETRACTED Han S, Sriariyanun M, Lee S, Sharma M, Bahar O, (and 2 more) (2011) Small Protein-Mediated Quorum Sensing in a Gram-Negative Bacterium PLoS ONE")
  end

  it "should display an updated mark for updated cites" do
    visit '/view/10.1371/journal.pone.0100404'

    expect(page).to have_content("UPDATED Fretwell PT, LaRue MA, Morin P, Kooyman GL, Wienecke B, (and 5 more) (2012) An Emperor Penguin Population Estimate: The First Global, Synoptic Survey of a Species from Space PLoS ONE")
  end

  it "should work when a reference is not actually cited in the paper" do
    visit '/view/10.1371/journal.pone.0100115'
  end    

  it "filter should work" do
    visit '/view/10.1371/journal.pone.0067380'
    fill_in('referencefilter', :with => 'motta')
    expect(page.first(:xpath, '//ol[@class="references"]//ol/li/div')['id']).to eq("reference_pone.0067380-Motta1")
  end    

  it "should display an interstitial page, then redirect" do
    visit '/view/10.1371/journal.pone.0067380'
    click_link('Surface and underwater observations of cooperatively feeding killer whales in northern Norway')
    # get the other window handle
    redir_window = (page.driver.browser.window_handles - [page.driver.current_window_handle])[0]
    within_window(redir_window) do
#      expect(page).to have_content("Originating page Oliver SP; Turner JR; Gann K; Silvosa M; D'Urban Jackson T Thresher Sharks Use Tail-Slaps as a Hunting Strategy")
#      expect(page).to have_content("Destination Similä T; Ugarte F Surface and underwater observations of cooperatively feeding killer whales in northern Norway Can. J. Zool.")
      # after redirect
      expect(page).to have_content("Get an email alert for the latest issue")
      page.driver.browser.close
    end
  end

  it "should clear the filter when a user clicks on a reference" do
    visit "/view/10.1371/journal.pone.0067380"
    fill_in('referencefilter', :with => 'kinematic')
    expect(page.first(:xpath, '//ol[@class="references"]//ol/li/div')['id']).to eq("reference_pone.0067380-Domenici1")
    click_link("[5]")
    expect(page.first(:xpath, '//ol[@class="references"]//ol/li/div')['id']).to eq("reference_pone.0067380-Clua1")
  end

  it "should display a volume number if there is no DOI" do
    visit "/view/10.1371/journal.pone.0067380"
    expect(page).to have_content("Killer whales (Orcinus orca) feeding on schooling herring (Clupea harengus) using underwater tail-slaps: kinematic analyses of field observations
J Exp Biol 203: 283-294")
  end

  it 'should display titles with italics' do
    visit '/view/10.1371/journal.pone.0067380'

    expect(page.find(:xpath, '/html/body/div[1]/div[1]/div/div/div[3]/div[2]/div[10]/ol/div/div[2]/div/div[1]/ol/li[3]/div/span[3]/span[2]/span[1]/span/em[1]').text)
      .to eq('Orcinus orca')
  end

  it 'should display & then hide a spinner' do
    visit '/view/10.1371/journal.pone.0067372'
    # this was failing because things moved too fast
    #expect(page).to have_content("Loading rich citations")
    #expect(page).to have_xpath("//img[@src='/assets/loader.gif']")
    # should go away after loading citations
    expect(page).to have_content("Palumbi SR (2004) MARINE RESERVES AND OCEAN NEIGHBORHOODS: The Spatial Scale of Marine Populations and Their Management Annual Review of Environment and Resources")
    expect(page).to_not have_content('Loading rich citations')
    expect(page).to_not have_xpath('//img[@src="/assets/loader.gif"]')
  end

  it 'should group cc-nc with free to read and reuse' do
    visit '/view/10.1371/journal.pone.0102160'
  end
end

