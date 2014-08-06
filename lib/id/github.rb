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

module Id
  class Github < Base
    # Github reference with or without commit
    # git@github.com:{owner}/{repo}(.git) or https://github.com/{owner}/{repo}(.git)
    # Optionally followed by (/commit/{sha})

    GITHUB             = '( (https?:\/\/) | (git@) ) github\.com [\/:] (\w+\/\w+) (\.git)?'
    GITHUB_ALONE       = GITHUB + '(\/)?'
    GITHUB_WITH_COMMIT = GITHUB + '\/commit\/\w{8,60}'

    GITHUB_ALONE_REGEX       = /(?<result>#{GITHUB_ALONE      })/iox
    GITHUB_WITH_COMMIT_REGEX = /(?<result>#{GITHUB_WITH_COMMIT})/iox

    COMMIT_PART    = '(\/commit\/(?<commit>\w+))'
    ID_PARTS_REGEX = /github\.com[:\/] (?<owner>\w+) \/ (?<repo>\w+) (\.git)?  ($ |  #{COMMIT_PART} ) /iox

    def self.extract(text)
      normalize( match_regexes(text, GITHUB_WITH_COMMIT_REGEX => false,
                                     GITHUB_ALONE_REGEX             => false) )
    end

    def self.normalize(id)
      return nil unless id.present?
      id.strip.sub(/\/$/,'')
    end

    # parse an id into its citeproc like components
    def self.parse(id)
      return nil unless id.present?

      id = normalize(id)
      matches = id.match(ID_PARTS_REGEX)

      if matches
        {
            URL:           id,
            GITHUB_OWNER:  matches[:owner],
            GITHUB_REPO:   "#{matches[:owner]}/#{matches[:repo]}",
            GITHUB_COMMIT: matches[:commit],
        }.compact

      else
        {
            URL:           id,
        }

      end
    end

  end
end
