#!/usr/bin/env ./bin/rails runner

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

raise "Out of date"

Rails.logger = Logger.new($stdout)

require 'pp'
require 'benchmark'

DOI ='10.1371/journal.pone.0046843'

xml = Plos::Api.document( DOI )
parser = PaperParser.new(xml)

class PaperParser
  def reference_nodes_text
    @reference_nodes_text ||= reference_nodes.map { |n| n.text }
  end
end

search_texts = parser.reference_nodes_text
puts "DOI #{DOI} has #{search_texts.count} reference nodes"

# Benchmark.bmbm do |bm|
#   (0..10).each do |n|
#     nn = n*3+1
#     refs = search_texts[ 0..(nn-1) ]
#     bm.report("#{nn} nodes #{refs.length}") {
#       Plos::Api.cross_refs(refs)
#     }
#   end
# end

puts '----------------------------'
puts  'refs >    total   per.ref'
puts '----------------------------'
iterations = 5
(0..16).each do |n|
  nn = n*3+1
  refs = search_texts[ 0..(nn-1) ]
  total = Benchmark.realtime do
    iterations.times {
     Plos::Api.cross_refs(refs)
    }
  end
  per_iteration = total / iterations
  per_ref = per_iteration / nn
  puts '%2d -->  %5f %5f' % [nn, per_iteration, per_ref]
end
puts '----------------------------'
puts  'refs >    total   per.ref'
puts '----------------------------'

