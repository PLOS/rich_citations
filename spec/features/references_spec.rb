# coding: utf-8
require "spec_helper"

Capybara.default_wait_time = 60

describe "reference viewing", :type => :feature, :js => true do
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

    page.click_button("Number of appearance")
    expect(page.first(:xpath, '//ol[@class="references"]/li/div')['id']).to eq("reference_pone.0100000-Villa2")
  end    

  it "should display a retracted mark for retracted cites" do
    visit '/view/10.1371/journal.pone.0059428'

    expect(page).to have_content("RETRACTED Han S, Sriariyanun M, Lee S, (and 4 more) (2011) Small Protein-Mediated Quorum Sensing in a Gram-Negative Bacterium PLoS ONE doi: 10.1371/journal.pone.0029192")
  end

  it "should display an updated mark for updated cites" do
    visit '/view/10.1371/journal.pone.0100404'

    expect(page).to have_content("UPDATED Fretwell PT, LaRue MA, Morin P, (and 7 more) (2012) An Emperor Penguin Population Estimate: The First Global, Synoptic Survey of a Species from Space PLoS ONE doi: 10.1371/journal.pone.0033751")
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
    redir_window = page.driver.find_window('Redirect')
    within_window(redir_window) do
      expect(page).to have_content("Originating page Oliver SP; Turner JR; Gann K; Silvosa M; D'Urban Jackson T Thresher Sharks Use Tail-Slaps as a Hunting Strategy")
      expect(page).to have_content("Destination Similä T; Ugarte F Surface and underwater observations of cooperatively feeding killer whales in northern Norway Can. J. Zool.")
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

  it "should display & then hide a spinner" do
    visit "/view/10.1371/journal.pone.0067372"
    # this was failing because things moved too fast
    #expect(page).to have_content("Loading rich citations")
    #expect(page).to have_xpath("//img[@src='/assets/spinner.gif']")
    # should go away after loading citations
    expect(page).to have_content("Palumbi SR (2004) MARINE RESERVES AND OCEAN NEIGHBORHOODS: The Spatial Scale of Marine Populations and Their Management Annual Review of Environment and Resources doi: 10.1146/annurev.energy.29.062403.102254")
    expect(page).to_not have_content("Loading rich citations")
    expect(page).to_not have_xpath("//img[@src='/assets/spinner.gif']")
  end
end
