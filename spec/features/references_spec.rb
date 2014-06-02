# coding: utf-8
require "spec_helper"

describe "reference viewing", :type => :feature, :js => true do
  it "should properly sort a references list" do
    visit '/view/10.1371/journal.pone.0067380'
    expect(page.first(:xpath, '//ol[@class="references"]/li').text).to eq("1. Clua E, Grosvalet F (2000) Mixed-species feeding aggregation of dolphins, large tunas and seabirds in the Azores. Aquat. Living Resour. 14: 11–18. Appears 4 times in this paper. ▶")

    page.click_link("Title")
    expect(page.first(:xpath, '//ol[@class="references"]/li').text).to eq("27. Simon M, Wahlberg M, Ugarte F, Miller LA (2005) Acoustic characteristics of underwater tail slaps used by Norwegian and Icelandic killer whales (Orcinus orca) to debilitate herring (Clupea harengus). J Exp Biol 208: 2459–2466. Appears 2 times in this paper. ▶")

    page.click_link("Mentions")
    expect(page.first(:xpath, '//ol[@class="references"]/li').text).to eq("3. Domenici P, Batty RS, Simila T, Ogam E (1999) Killer whales (Orcinus orca) feeding on schooling herring (Clupea harengus) using underwater tail-slaps: kinematic analyses of field observations. J Exp Biol 203: 283–294. Appears 8 times in this paper. ▶")

    page.click_link("Year")
    expect(page.first(:xpath, '//ol[@class="references"]/li').text).to eq("25. Sperone E, Micarelli P, Andreotti S, Brandmayr P, Bernabo I, et al. (2012) Surface behaviour of bait-attracted white sharks at Dyer Island (South Africa). Mar Biol Res 8: 982–991. Appears once in this paper. ▶")

    page.click_link("Author")
    expect(page.first(:xpath, '//ol[@class="references"]/li').text).to eq("17. Aalbers SA, Bernal D, Sepulveda CA (2010) The functional role of the caudal fin in the feeding ecology of the common thresher shark Alopias vulpinus. J Fish Biol 76: 1863–1868. Appears 3 times in this paper. ▶")

    page.click_link("Journal")
    expect(page.first(:xpath, '//ol[@class="references"]//ol/li').text).to eq("4. O'Donoghue SH, Drapeau L, Dudley SFJ, Peddemors VM (2010) The KwaZulu-Natal sardine run: shoal distribution in relation to nearshore environmental conditions, 1997–2007. Afr J Mar Sci 32: 293–307. Appears 2 times in this paper. ▶")
  end
end
