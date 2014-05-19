#!/usr/bin/env ./bin/rails runner

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

