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

# Add sections node

module Processors
  class ReferencesMedianCoCitations < Base
    include Helpers

    def process
      references.each do |id, info|
        info[:median_co_citations] = median_co_citations(info)
      end
    end

    def self.dependencies
      [ ReferencesCitedGroups ]
    end

    protected

    # MICC = median in-line co-citations
    # aka micc_dictionary
    def median_co_citations(ref_info)
      cited_groups = ref_info[:citation_groups]

      if cited_groups.present?
        cocite_counts = cited_groups.map { |g| g[:count] - 1 }
        cocite_counts.median

      else
        nil

      end

    end

  end
end
