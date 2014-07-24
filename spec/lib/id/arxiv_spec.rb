require 'spec_helper'

describe Id::Arxiv do
  
  describe ':extract' do

    context "New Format (yymm.nnnn(Vn)" do

      it "should match a string starting with arxiv" do
        expect( Id::Arxiv.extract('arxiv:1407.1234') ).to eq('1407.1234')
        expect( Id::Arxiv.extract('Arxiv: 1407.1234') ).to eq('1407.1234')
      end

      it "should match a string starting with arxiv id" do
        expect( Id::Arxiv.extract('arxiv id:1407.1234') ).to eq('1407.1234')
        expect( Id::Arxiv.extract('ArxivId: 1407.1234') ).to eq('1407.1234')
      end

      it "should match a url starting with arxiv.org/abs/" do
        expect( Id::Arxiv.extract('arxiv.org/abs/1407.1234') ).to eq('1407.1234')
        expect( Id::Arxiv.extract('arxiv.org/abs/1407.1234') ).to eq('1407.1234')
      end

      it "should handle extra whitespace" do
        expect( Id::Arxiv.extract(' Arxiv: 1407.1234 ') ).to eq('1407.1234')
      end

      it "should not match Arxiv's with invalid lengths" do
        expect( Id::Arxiv.extract('Arxiv:1407.123456') ).to be_nil
        expect( Id::Arxiv.extract('Arxiv:14070.1234') ).to be_nil
        expect( Id::Arxiv.extract('Arxiv:1407.123') ).to be_nil
        expect( Id::Arxiv.extract('Arxiv:140.1234') ).to be_nil
      end

      it "should trim trailing punctuation" do
        expect( Id::Arxiv.extract('Arxiv:1407.1234. ') ).to eq('1407.1234')
      end

      it "should handle Arxiv id's with no period" do
        expect( Id::Arxiv.extract('Arxiv:14071234') ).to eq('1407.1234')
      end

      it "should handle a version suffix" do
        expect( Id::Arxiv.extract('Arxiv:1407.1234v12. ') ).to eq('1407.1234v12')
      end

      it "should not accept standlone ids" do
        expect( Id::Arxiv.extract('1407.1234v12') ).to be_nil
      end

    end

    context "Old Format (subject/yymmnnn" do

      it "should match a string starting with arxiv" do
        expect( Id::Arxiv.extract('arxiv:hep-lat.GT/1234567') ).to eq('hep-lat.GT/1234567')
        expect( Id::Arxiv.extract('Arxiv: hep-lat.GT/1234567') ).to eq('hep-lat.GT/1234567')
      end

      it "should match a url starting with arxiv.org/abs/" do
        expect( Id::Arxiv.extract('arxiv.org/abs/hep-lat.GT/1234567') ).to eq('hep-lat.GT/1234567')
        expect( Id::Arxiv.extract('arxiv.org/abs/hep-lat.GT/1234567') ).to eq('hep-lat.GT/1234567')
      end

      it "should handle extra whitespace" do
        expect( Id::Arxiv.extract(' Arxiv: hep-lat.GT/1234567 ') ).to eq('hep-lat.GT/1234567')
      end

      it "should not match Arxiv's with invalid lengths" do
        expect( Id::Arxiv.extract('Arxiv:hep-lat.GT/12345678') ).to be_nil
        expect( Id::Arxiv.extract('Arxiv:hep-lat.GT/12345') ).to be_nil
        expect( Id::Arxiv.extract('Arxiv:1234567') ).to be_nil
      end

      it "should trim trailing punctuation" do
        expect( Id::Arxiv.extract('Arxiv:hep-lat.GT/1234567. ') ).to eq('hep-lat.GT/1234567')
      end

      it "should handle a version suffix" do
        expect( Id::Arxiv.extract('Arxiv:hep-lat.GT/1234567v12. ') ).to eq('hep-lat.GT/1234567v12')
      end

      it "should not accept standlone ids" do
        expect( Id::Arxiv.extract('hep-lat.GT/1234567') ).to be_nil
      end

    end

  end

  describe "::is_id?" do

    it "should accept valid identifiers" do
      expect( Id::Arxiv.is_id?('1234.5678') ).to eq('1234.5678')
      expect( Id::Arxiv.is_id?('12345678') ).to eq('1234.5678')
      expect( Id::Arxiv.is_id?('hep-lat.GT/1234567') ).to eq('hep-lat.GT/1234567')
    end

    it "should fail" do
      expect( Id::Arxiv.is_id?('xyz') ).to be_falsy
    end

  end

  describe "::normalize" do

    it "should add a period in a new id if necessary" do
      expect( Id::Arxiv.normalize('1234.5678') ).to eq('1234.5678')
      expect( Id::Arxiv.normalize('12345678')  ).to eq('1234.5678')
    end

    it "should remove whitespace" do
      expect( Id::Arxiv.normalize('  1234.5678  ') ).to eq('1234.5678')
    end

  end

  describe "::without_version" do

    it "should remove the version" do
      expect( Id::Arxiv.without_version('1234.5678v12') ).to eq('1234.5678')
      expect( Id::Arxiv.without_version('1234.5678V12') ).to eq('1234.5678')
      expect( Id::Arxiv.without_version('12345678V12') ).to eq('1234.5678')
      expect( Id::Arxiv.without_version('hep-lat.GT/1234567v12') ).to eq('hep-lat.GT/1234567')
    end

    it "should not remove the version if there is none" do
      expect( Id::Arxiv.without_version('1234.5678') ).to eq('1234.5678')
      expect( Id::Arxiv.without_version('12345678') ).to eq('1234.5678')
      expect( Id::Arxiv.without_version('hep-lat.GT/1234567') ).to eq('hep-lat.GT/1234567')
    end

    it "should accept a nil or blank" do
      expect( Id::Arxiv.without_version(nil) ).to be_nil
      expect( Id::Arxiv.without_version('') ).to be_nil
    end

  end

end
