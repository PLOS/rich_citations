# coding: utf-8
require "spec_helper"

Capybara.default_wait_time = 60

describe "reference viewing", :type => :feature, :js => true do
  it "should properly sort a references list" do
    visit '/view/10.1371/journal.pone.0067380'
    expect(page.first(:xpath, '//ol[@class="references"]/li/div')['id']).to eq("reference_pone.0067380-Clua1")

    page.click_button("Title")
    expect(page.first(:xpath, '//ol[@class="references"]/li/div')['id']).to eq("reference_pone.0067380-Simon1")

    page.click_button("Appearances")
    expect(page.first(:xpath, '//ol[@class="references"]/li/div')['id']).to eq("reference_pone.0067380-Domenici1")

    page.click_button("Year")
    expect(page.first(:xpath, '//ol[@class="references"]/li/div')['id']).to eq("reference_pone.0067380-Sperone2")

    page.click_button("Author")
    expect(page.first(:xpath, '//ol[@class="references"]/li/div')['id']).to eq("reference_pone.0067380-Aalbers1")

    page.click_button("Journal")
    expect(page.first(:xpath, '//ol[@class="references"]//ol/li/div')['id']).to eq("reference_pone.0067380-ODonoghue1")
  end

  it "should have a show repeated citations button" do
    visit '/view/10.1371/journal.pone.0067380'
    
    expect(page).to have_button("Show repeated citations")

    # should be disabled on non-appearance sorts
    page.click_button("Title")
    expect(page).to have_button("Show repeated citations", disabled: true)
    page.click_button("Appearances")
    expect(page).to have_button("Show repeated citations", disabled: true)
    page.click_button("Year")
    expect(page).to have_button("Show repeated citations", disabled: true)
    page.click_button("Author")
    expect(page).to have_button("Show repeated citations", disabled: true)
    page.click_button("Journal")
    expect(page).to have_button("Show repeated citations", disabled: true)

  end

  it "should have a group citations button" do
    visit '/view/10.1371/journal.pone.0067380'
    
    # should not be visible until Show repeated citations toggled
    expect(page).to have_button("Group citations", disabled: true)

    page.click_button("Show repeated citations")
    expect(page).to have_button("Group citations")
  end

  it "should display a retracted mark for retracted cites" do
    visit '/view/10.1371/journal.pone.0059428'

    expect(page).to have_content("Small Protein-Mediated Quorum Sensing in a Gram-Negative Bacterium PLoS ONE 10.1371/journal.pone.0029192 RETRACTED")
  end

  it "should work when a reference is not actually cited in the paper" do
    visit '/view/10.1371/journal.pone.0100115'
  end    
end
