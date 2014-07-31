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

module Spec
  module ProcessorHelper
    extend ActiveSupport::Concern

    included do

      include Spec::XmlBuilder

      before do
        allow(IdentifierResolver).to receive(:resolvers).and_return(IdentifierResolver::TEST_RESOLVERS)
      end

    end

    def processors(processor_classes, resolve_dependencies=true)
      @xml    ||= xml
      @result ||= {}

      processor_classes ||= []
      processor_classes << described_class
      processor_classes = PaperParser.resolve_dependencies(processor_classes) if resolve_dependencies

      processor_classes.map { |klass| klass.new(@xml, @result) }
    end

    def process(result=nil, *processor_classes)
      @result ||= result
      processors = processors(processor_classes, result.blank?)
      processors.each(&:process)
      processors.each(&:cleanup)
      @result
    end

    def cleanup(result, *processor_classes)
      @result = result

      processor_classes << described_class unless described_class.in?(processor_classes)
      processors = processor_classes.map { |klass| klass.new(@xml, @result) }

      processors.each(&:cleanup)
      @result
    end

    def result
      @result ||= process
    end

  end
end
