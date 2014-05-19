module Resolvers
  class Base

    attr_reader :root, :unresolved_references

    def self.resolve(root)
      unresolved_references = root.unresolved_references
      return if unresolved_references.empty?
      new(root, unresolved_references).resolve
    end

    def resolve
      raise "Please implement me"
    end

    def initialize(root, unresolved_references)
      @root                  = root
      @unresolved_references = unresolved_references
    end

  end
end