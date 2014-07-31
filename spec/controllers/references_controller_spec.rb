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
require "spec_helper"

describe ReferencesController, type: :controller do
  describe "GET '/references/10.1007%2Fs00114-005-0614-4" do
    it "works for RIS data" do
      get 'show', id: '10.1007/s00114-005-0614-4', format: 'ris'
      expect(response).to be_success
      expect(response.content_type).to eq("application/x-research-info-systems")
      expect(response.body).to eq("""TY  - JOUR
DO  - 10.1007/s00114-005-0614-4
UR  - http://dx.doi.org/10.1007/s00114-005-0614-4
TI  - Caudal fin allometry in the white shark Carcharodon carcharias: implications for locomotory performance and ecology
T2  - Naturwissenschaften
AU  - Lingham-Soliar, Theagarten
PY  - 2005
DA  - 2005/03/17
PB  - Springer Science + Business Media
SP  - 231-236
IS  - 5
VL  - 92
SN  - 0028-1042
SN  - 1432-1904
ER  - 
""")
    end
    it "works for bibtex data" do
      get 'show', id: '10.1007/s00114-005-0614-4', format: 'bibtex'
      expect(response).to be_success
      expect(response.content_type).to eq("application/x-bibtex")
      expect(response.body).to eq("""@article{Lingham_Soliar_2005,
	doi = {10.1007/s00114-005-0614-4},
	url = {http://dx.doi.org/10.1007/s00114-005-0614-4},
	year = 2005,
	month = {Mar},
	publisher = {Springer Science + Business Media},
	volume = {92},
	number = {5},
	pages = {231-236},
	author = {Theagarten Lingham-Soliar},
	title = {Caudal fin allometry in the white shark Carcharodon carcharias: implications for locomotory performance and ecology},
	journal = {Naturwissenschaften}
}""")
    end
  end
end
