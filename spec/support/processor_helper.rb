module Spec
  module ProcessorHelper
    extend ActiveSupport::Concern

    included do

      include Spec::XmlBuilder

      before do
        allow(ReferenceResolver).to receive(:resolvers).and_return(ReferenceResolver::TEST_RESOLVERS)
      end

    end

    def processors(*processor_classes)
      @xml    ||= xml
      @result_set ||= {}

      processor_classes << described_class
      processor_classes = PaperParser.resolve_dependencies(processor_classes)

      processor_classes.map { |klass| klass.new(@xml, @result_set) }
    end

    def process(*processor_classes)
      processors = processors(*processor_classes)
      processors.each(&:process)
      processors.each(&:cleanup)
      @result_set
    end

    def cleanup(result, *processor_classes)
      @result_set = result

      processor_classes << described_class unless described_class.in?(processor_classes)
      processor_classes.map { |klass| klass.new(@xml, @result_set) }

      processors.each(&:cleanup)
      @result_set
    end

    def result
      @result_set ||= process
    end

  end
end