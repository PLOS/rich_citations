# coding: utf-8
require "spec_helper"

describe PapersController, type: :controller do
  describe "GET '/view/10.1371/journal.pone.0067380'" do
    it "returns http success" do
      get 'view', id: '10.1371/journal.pone.0067380'
      expect(response).to be_success
    end
  end
  
  describe "GET '/view/10.1371/journal.pone.0067380/references/1'" do
    it "returns http success" do
      get :reference, id: '10.1371/journal.pone.0067380', referenceid: '2'
      expect(response).to be_success
      parsed = JSON.parse(response.body)
      expect(parsed["info"]["author"]).to eq([{"family"=>"Similä", "given"=>"Tiu"}, {"family"=>"Ugarte", "given"=>"Fernando"}])
    end
  end

  describe "GET '/interstitial&from=10.1371%2Fjournal.pone.0067380&to=1'" do
    it "returns http success" do
      get :interstitial, from: '10.1371/journal.pone.0067380', to: '1'
      expect(response).to be_success
    end
  end
end
