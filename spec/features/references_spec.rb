# coding: utf-8
require "spec_helper"

describe "reference viewing", :type => :feature, :js => true do
  it "should properly sort a references list" do
    visit '/view/10.1371/journal.pone.0067380'
    expect(page.first(:xpath, '//ol[@class="references"]/li/div')['id']).to eq("reference_pone.0067380-Clua1")

    page.click_link("Title")
    expect(page.first(:xpath, '//ol[@class="references"]/li/div')['id']).to eq("reference_pone.0067380-Simon1")

    page.click_link("Mentions")
    expect(page.first(:xpath, '//ol[@class="references"]/li/div')['id']).to eq("reference_pone.0067380-Domenici1")

    page.click_link("Year")
    expect(page.first(:xpath, '//ol[@class="references"]/li/div')['id']).to eq("reference_pone.0067380-Sperone2")

    page.click_link("Author")
    expect(page.first(:xpath, '//ol[@class="references"]/li/div')['id']).to eq("reference_pone.0067380-Aalbers1")

    page.click_link("Journal")
    expect(page.first(:xpath, '//ol[@class="references"]//ol/li/div')['id']).to eq("reference_pone.0067380-ODonoghue1")
  end
end
