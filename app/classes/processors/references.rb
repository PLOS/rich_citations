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
  class References < Base
    include Helpers

    def process

      references = result[:references] = []

      reference_nodes.each do |number, node|
         id = node[:id]

        reference   = {
            id:     id,
            number: number,
            node:   remove_label(node),       # for other processors
        }

        references << reference
      end

    end

    def cleanup
      references.each do |ref|
        ref.delete(:node)
        ref.compact!
      end
    end

    def self.dependencies
      [Doi, PaperInfo] #@todo can be removed after refactoring
    end

    protected

    def reference_nodes
      @reference_nodes ||= begin
        xml.css('ref-list ref').map.with_index{ |node, index| [index+1, node] }.to_h
      end
    end

    def remove_label(node)
      label = node.css('label')
      label.remove if label.present?
      node
    end

  end
end
