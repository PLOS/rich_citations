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

require 'spec_helper'

describe Id::Github do
  
  describe '#extract' do

    it "should extract an https github id" do
      expect( Id::Github.extract('https://github.com/ploslabs/citation_tools'     ) ).to eq('https://github.com/ploslabs/citation_tools')
      expect( Id::Github.extract('https://github.com/ploslabs/citation_tools.git' ) ).to eq('https://github.com/ploslabs/citation_tools.git')
      expect( Id::Github.extract('https://github.com/ploslabs/citation_tools/'    ) ).to eq('https://github.com/ploslabs/citation_tools')
      expect( Id::Github.extract('https://github.com/ploslabs/citation_tools.git/') ).to eq('https://github.com/ploslabs/citation_tools.git')
    end

    it "should extract an http github id" do
      expect( Id::Github.extract('http://github.com/ploslabs/citation_tools'     ) ).to eq('http://github.com/ploslabs/citation_tools')
      expect( Id::Github.extract('http://github.com/ploslabs/citation_tools.git' ) ).to eq('http://github.com/ploslabs/citation_tools.git')
      expect( Id::Github.extract('http://github.com/ploslabs/citation_tools/'    ) ).to eq('http://github.com/ploslabs/citation_tools')
      expect( Id::Github.extract('http://github.com/ploslabs/citation_tools.git/') ).to eq('http://github.com/ploslabs/citation_tools.git')
    end

    it "should extract an https github id with a commit" do
      expect( Id::Github.extract('https://github.com/ploslabs/citation_tools/commit/b829df90ea5facf0acb1c2fd7a2cc81e0825d63c'    ) ).to eq('https://github.com/ploslabs/citation_tools/commit/b829df90ea5facf0acb1c2fd7a2cc81e0825d63c')
      expect( Id::Github.extract('https://github.com/ploslabs/citation_tools.git/commit/b829df90ea5facf0acb1c2fd7a2cc81e0825d63c') ).to eq('https://github.com/ploslabs/citation_tools.git/commit/b829df90ea5facf0acb1c2fd7a2cc81e0825d63c')
    end

    it "should match a ssh git id" do
      expect( Id::Github.extract('git@github.com:ploslabs/citation_tools'     ) ).to eq('git@github.com:ploslabs/citation_tools')
      expect( Id::Github.extract('git@github.com:ploslabs/citation_tools.git' ) ).to eq('git@github.com:ploslabs/citation_tools.git')
      expect( Id::Github.extract('git@github.com:ploslabs/citation_tools/'    ) ).to eq('git@github.com:ploslabs/citation_tools')
      expect( Id::Github.extract('git@github.com:ploslabs/citation_tools.git/') ).to eq('git@github.com:ploslabs/citation_tools.git')
    end

    it "should match a ssh git id with a commit" do
      expect( Id::Github.extract('git@github.com:ploslabs/citation_tools/commit/b829df90ea5facf0acb1c2fd7a2cc81e0825d63c'     ) ).to eq('git@github.com:ploslabs/citation_tools/commit/b829df90ea5facf0acb1c2fd7a2cc81e0825d63c')
      expect( Id::Github.extract('git@github.com:ploslabs/citation_tools.git/commit/b829df90ea5facf0acb1c2fd7a2cc81e0825d63c' ) ).to eq('git@github.com:ploslabs/citation_tools.git/commit/b829df90ea5facf0acb1c2fd7a2cc81e0825d63c')
    end

    it "should handle extra whitespace" do
      expect( Id::Github.extract('git@github.com:ploslabs/citation_tools  '     ) ).to eq('git@github.com:ploslabs/citation_tools')
      expect( Id::Github.extract('https://github.com/ploslabs/citation_tools  '     ) ).to eq('https://github.com/ploslabs/citation_tools')
    end

    it "should trim trailing punctuation" do
      expect( Id::Github.extract('git@github.com:ploslabs/citation_tools.  '     ) ).to eq('git@github.com:ploslabs/citation_tools')
      expect( Id::Github.extract('https://github.com/ploslabs/citation_tools.  '     ) ).to eq('https://github.com/ploslabs/citation_tools')
    end

  end

  describe '#normalize' do

    it "should remove a trailing backslash" do
      expect( Id::Github.normalize('https://ploslabs/citation_tools/' ) ).to eq('https://ploslabs/citation_tools')
    end

    it "should remove whitespace" do
      expect( Id::Github.normalize('  https://ploslabs/citation_tools   ' ) ).to eq('https://ploslabs/citation_tools')
    end

  end

  describe '#parse' do

    it "should parse a http/s url" do
      expect( Id::Github.parse('https://github.com/ploslabs/citation_tools' ) ).to eq(
                                URL:          "https://github.com/ploslabs/citation_tools",
                                GITHUB_OWNER: "ploslabs",
                                GITHUB_REPO:  "ploslabs/citation_tools"                )
    end

    it "should parse a gihub url" do
      expect( Id::Github.parse('git@github.com:ploslabs/citation_tools' ) ).to eq(
                                                                                       URL:          "git@github.com:ploslabs/citation_tools",
                                                                                       GITHUB_OWNER: "ploslabs",
                                                                                       GITHUB_REPO:  "ploslabs/citation_tools"                )
    end

    it "should parse a url with a trailing backslash" do
      expect( Id::Github.parse('https://github.com/ploslabs/citation_tools/' ) ).to eq(
                                                                                       URL:          "https://github.com/ploslabs/citation_tools",
                                                                                       GITHUB_OWNER: "ploslabs",
                                                                                       GITHUB_REPO:  "ploslabs/citation_tools"                )
    end

    it "should parse a url containing .git" do
      expect( Id::Github.parse('https://github.com/ploslabs/citation_tools.git' ) ).to eq(
                                                                                        URL:          "https://github.com/ploslabs/citation_tools.git",
                                                                                        GITHUB_OWNER: "ploslabs",
                                                                                        GITHUB_REPO:  "ploslabs/citation_tools"                )

      expect( Id::Github.parse('https://github.com/ploslabs/citation_tools.git/' ) ).to eq(
                                                                                           URL:          "https://github.com/ploslabs/citation_tools.git",
                                                                                           GITHUB_OWNER: "ploslabs",
                                                                                           GITHUB_REPO:  "ploslabs/citation_tools"                )

    end

    it "should parse a url containing a commit sha" do
      expect( Id::Github.parse('https://github.com/ploslabs/citation_tools/commit/abcdefgh' ) ).to eq(
                                                                                        URL:           "https://github.com/ploslabs/citation_tools/commit/abcdefgh",
                                                                                        GITHUB_OWNER:  "ploslabs",
                                                                                        GITHUB_REPO:   "ploslabs/citation_tools",
                                                                                        GITHUB_COMMIT: "abcdefgh")
    end

  end

end
