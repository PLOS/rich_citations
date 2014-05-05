
module Plos
  class NodeUtilities

    def self.word_count(node)
      count = 1
      node.traverse do |n|
        return count if n==node
        count+= n.text.word_count if n.text?
      end

      nil
    end


    def self.word_count_upto(node, upto)

      count = 1
      node.traverse do |n|
        return count if n==upto
        count+= n.text.word_count if n.text?
      end

      nil
    end

  end

end