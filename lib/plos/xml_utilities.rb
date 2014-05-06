
module Plos
  class XmlUtilities

    # Like Xml::Node.text but uses the same logic used by the other text
    def self.text(container)
      container.text.strip
      # self.text_before(container, nil).try(:strip)
    end

    # Adds spaces where nodes break and removes multiple spaces.
    # i.e. <first>J</first><last>Smith</last> becomes 'J Smith'
    def self.spaced_text(container)
      text_nodes = container.xpath('.//text()').map(&:text)
      text = text_nodes.join(" ")
      clean_text = text.squish
    end

    # Text up to a node
    def self.text_before(container, node)
      text = ''
      container = container.first if container.is_a?(Nokogiri::XML::NodeSet)
      breadth_traverse(container) do |n|
        return text.lstrip if n == node
        text += n.text if n.text?
      end

      # If node is not found it is a failure
      node ? nil : text.lstrip
    end

    # Text after a node
    def self.text_after(container, node)
      text = ''
      found = false
      container = container.first if container.is_a?(Nokogiri::XML::NodeSet)

      depth_traverse(container) do |n|
        if found
          text += n.text if n.text?
        end
        if n == node
          found = true
        end
      end

      # If node is not found it is a failure
      found ? text.rstrip : nil
    end

    # Get the outermost section title
    def self.nearest(node, types)
      node = node.parent

      while node && defined?(node.parent)
        return node if types.include?(node.name.downcase)
        node = node.parent
      end

      return nil
    end

    def self.breadth_traverse(container, &block)
      block.call(container)
      container.children.each{ |j| breadth_traverse(j, &block) }
    end

    def self.depth_traverse(container, &block)
      container.traverse(&block)
    end

  end

end