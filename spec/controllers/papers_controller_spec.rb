# coding: utf-8
# Copyright (c) 2014 Public Library of Science

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# coding: utf-8
require 'spec_helper'
require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'fixtures/vcr_cassettes'
  c.hook_into :webmock
end

describe PapersController, type: :controller do
  describe "GET '/view/10.1371/journal.pone.0067380'" do
    it 'returns http success' do
      VCR.use_cassette('view_journal.pone.0067380') do
        get :view, id: '10.1371/journal.pone.0067380'
        expect(response).to be_success
      end
    end
  end

  describe "GET '/view/10.1371/journal.pone.0067380/references/1'" do
    it 'returns http success' do
      VCR.use_cassette('view_journal.pone.0067380') do
        get :reference, id: '10.1371/journal.pone.0067380', referenceid: '2'
        expect(response).to be_success
        parsed = JSON.parse(response.body)
        expect(parsed['bibliographic']['author']).to eq([{ 'family' => 'Similä', 'given' => 'Tiu' },
                                                         { 'family' => 'Ugarte', 'given' => 'Fernando' }])
      end
    end
  end

  describe "GET '/interstitial&from=10.1371%2Fjournal.pone.0067380&to=1'" do
    it 'returns http success' do
      VCR.use_cassette('view_journal.pone.0067380') do
        get :interstitial, from: '10.1371/journal.pone.0067380', to: '1'
        expect(response).to be_success
      end
    end
  end
end
