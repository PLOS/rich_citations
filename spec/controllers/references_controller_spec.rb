require "spec_helper"

describe ReferencesController do
  describe "GET '/references/10.1007%2Fs00114-005-0614-4" do
    it "returns http success" do
      get 'show', id: '10.1007/s00114-005-0614-4'
      expect(response).to be_success
    end
  end
end
