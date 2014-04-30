# Used if no other resolvers succeed

class Plos::FailResolver < Plos::BaseResolver

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