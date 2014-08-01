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
  class ReferencesAbstract < Base
    include Helpers

    def process
      plos_references = references_for_type(:doi).select { |ref| Id::Doi.is_plos_doi?(ref[:id]) }
      plos_references_without_abstracts = plos_references.reject { |ref| ref[:info] && ref[:info][:abstract] }

      add_abstracts(plos_references_without_abstracts) if plos_references_without_abstracts.present?
    end

    def self.dependencies
      ReferencesInfoCacheLoader
    end

    protected

    def add_abstracts(references)
      dois    = references.map{ |ref| ref[:id] }
      results = Plos::Api.search_dois(dois)

      results.each do |result|
        if result['abstract']
          reference = references.find { |ref| (ref[:id] == result['id']) }
          next unless reference
          info = reference[:info] ||= {}
          info[:abstract] = result['abstract'].first.strip
        end
      end
    end

  end
end
