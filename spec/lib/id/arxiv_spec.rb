require 'spec_helper'

describe Id::Arxiv do
  
  describe '#extract' do

    context "New Format (yymm.nnnn(Vn)" do

      it "should match a string starting with arxiv" do
        expect( Id::Arxiv.extract('arxiv:1407.1234') ).to eq('1407.1234')
        expect( Id::Arxiv.extract('Arxiv: 1407.1234') ).to eq('1407.1234')
      end

      it "should match a url starting with arxiv.org/abs/" do
        expect( Id::Arxiv.extract('arxiv.org/abs/1407.1234') ).to eq('1407.1234')
        expect( Id::Arxiv.extract('arxiv.org/abs/1407.1234') ).to eq('1407.1234')
      end

      it "should handle extra whitespace" do
        expect( Id::Arxiv.extract(' Arxiv: 1407.1234 ') ).to eq('1407.1234')
      end

      it "should not match Pmid's with invalid lengths" do
        expect( Id::Arxiv.extract('Arxiv:1407.123456') ).to be_nil
        expect( Id::Arxiv.extract('Arxiv:14070.1234') ).to be_nil
        expect( Id::Arxiv.extract('Arxiv:1407.123') ).to be_nil
        expect( Id::Arxiv.extract('Arxiv:140.1234') ).to be_nil
      end

      it "should trim trailing punctuation" do
        expect( Id::Arxiv.extract('Arxiv:1407.1234. ') ).to eq('1407.1234')
      end

      it "should handle a version suffix" do
        expect( Id::Arxiv.extract('Arxiv:1407.1234v12. ') ).to eq('1407.1234v12')
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

      it "should not match Pmid's with invalid lengths" do
        expect( Id::Arxiv.extract('Arxiv:hep-lat.GT/12345678') ).to be_nil
        expect( Id::Arxiv.extract('Arxiv:hep-lat.GT/12345') ).to be_nil
        expect( Id::Arxiv.extract('Arxiv:1234567') ).to be_nil
      end

      it "should trim trailing punctuation" do
        expect( Id::Arxiv.extract('Arxiv:hep-lat.GT/1234567. ') ).to eq('hep-lat.GT/1234567')
      end

    end

  end

end
