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

module Processors
  class ReferencesIdentifier < Base
    include Helpers

    def process
      references.each do |ref|
        id   = ref[:id]
        info = identifier_for_reference[id]

        ref.merge!(
          bibliographic:   info.except(:uri, :uri_type, :uri_source, :score, :accessed_at),
          uri:             info[:uri],
          uri_type:        info[:uri_type],
          uri_source:      info[:uri_source],
          score:           info[:score],
          accessed_at:     info[:accessed_at]
        ) if info

      end

    end

    def cleanup
      references.each do |ref|
        info = ref[:bibliographic]
        info.compact! if info
        ref.delete(:bibliographic) if info.blank?
      end
    end

    def self.dependencies
      References
    end

    protected

    def identifier_for_reference
      @identifier_for_reference ||= begin
        reference_nodes = references.map { |ref| [ref[:id], ref[:node]] }.to_h
        IdentifierResolver.resolve(reference_nodes)
      end
    end

  end
end
