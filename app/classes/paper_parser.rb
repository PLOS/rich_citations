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

    resolved = []
    klasses = klasses.sort_by { |klass| klass.priority }
    add_dependencies.(resolved, klasses)
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
