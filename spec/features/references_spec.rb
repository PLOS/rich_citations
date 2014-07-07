# coding: utf-8
require "spec_helper"

Capybara.default_wait_time = 60

describe "reference viewing", :type => :feature, :js => true do
  it "should properly sort a references list" do
    visit '/view/10.1371/journal.pone.0067380'
    expect(page.first(:xpath, '//ol[@class="references"]/li/div')['id']).to eq("reference_pone.0067380-Clua1")

    page.click_button("Title")
    expect(page.first(:xpath, '//ol[@class="references"]/li/div')['id']).to eq("reference_pone.0067380-Simon1")

    page.click_button("Order in paper")
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
  end

  it "should display a retracted mark for retracted cites" do
    visit '/view/10.1371/journal.pone.0059428'

    expect(page).to have_content("Small Protein-Mediated Quorum Sensing in a Gram-Negative Bacterium PLoS ONE doi: 10.1371/journal.pone.0029192 RETRACTED CC-BY")
  end

  it "should work when a reference is not actually cited in the paper" do
    visit '/view/10.1371/journal.pone.0100115'
  end    
end
