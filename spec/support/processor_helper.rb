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