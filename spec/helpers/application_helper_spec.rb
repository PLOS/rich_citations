require "spec_helper"

describe ApplicationHelper, type: :helper do
  describe "#format_author_name_inverted_initials" do
    it "formats authors properly " do
      format_author_name_inverted_initials({given: "Jane", family: "Roe"}).should eql("Roe J")
      format_author_name_inverted_initials({given: "Mary Jane", family: "Roe"}).should eql("Roe MJ")
      format_author_name_inverted_initials({given: "Jane", family: "Roe Doe"}).should eql("Roe Doe J")
      format_author_name_inverted_initials({given: "Jane", family: "Roe-Doe"}).should eql("Roe-Doe J")
    end
  end
end
