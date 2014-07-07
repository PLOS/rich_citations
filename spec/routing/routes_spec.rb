require 'spec_helper'

RSpec.describe "papers routing", type: :routing do
  it "routes /view/10.1371/journal.pone.0067380 to profile#view" do
    expect(get: "/view/10.1371/journal.pone.0067380").to route_to(
      controller: "papers",
      action: "view",
      id: "10.1371/journal.pone.0067380")
  end
  
  it "routes /view/10.1371/journal.pone.0067380/references/1 to profile#references" do
    expect(get: "/view/10.1371/journal.pone.0067380/references/1").to route_to(
      controller: "papers",
      action: "reference",
      id: "10.1371/journal.pone.0067380",
      referenceid: "1")
  end
end
