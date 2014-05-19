# Used if no other resolvers succeed

module Resolvers
  class Fail < Base

    def resolve
      unresolved_references.each do |index, node|
        info = {
            text: node.text,
            score: nil,
        }
        if ! root.results[index]
          root.set_result(index, nil, info )
        end
      end
    end

  end
end