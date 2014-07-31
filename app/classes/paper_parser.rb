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

class PaperParser

  def self.is_failure?(paper_info)
    paper_info.blank? || paper_info[:failed]
  end

  attr_reader :xml, :result

  def self.parse_xml(xml)
    new(xml).parse
  end

  def self.parse_doi(doi)
    xml = Plos::Api.document( doi )
    new(xml).parse
  end

  def parse
    return failure unless xml

    @result = create_result
    run_all_processors
    cleanup_all_processors
    @result
  end

  protected

  def initialize(xml)
    @xml = xml
  end

  def failure
    {
        failed: true
    }
  end

  def create_result
    {}
  end

  def run_all_processors
    processors.each do |processor|
      processor.process
    end
  end

  def cleanup_all_processors
    processors.each do |processor|
      processor.cleanup
    end
  end

  def processors
    @all_processors ||= begin
      klasses = self.class.resolved_processor_classes
      klasses.map { |klass| klass.new(xml, result) }
    end
  end

  def self.resolved_processor_classes
    resolve_dependencies(processor_classes)
  end

  def self.resolve_dependencies(klasses)
    add_dependencies = lambda do |resolved, klasses|
                         klasses.each do |klass|
                           if !klass.in?(resolved)
                             add_dependencies.(resolved, Array(klass.dependencies) )
                             resolved << klass
                           end
                         end
                       end

    sorted_klasses = klasses.sort { |a, b|
      ( a.priority <=> b.priority ) * 2 +
      (a.name      <=> b.name    )  * 1
    }

    resolved = []
    add_dependencies.(resolved, sorted_klasses)
    resolved
  end

  def self.processor_classes
    load_processor_classes
  end

  def self.load_processor_classes

    @classes ||= Dir[Rails.root.join( File.dirname(__FILE__), 'processors', '*.rb')].map do |fn|
      name  = File.basename(fn, '.rb')
      klass = "processors/#{name}".camelcase.constantize
      klass if klass < Processors::Base
    end.compact

  end

end
