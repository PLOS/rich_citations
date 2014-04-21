# Used if no other resolvers succeed

class Plos::FailResolver < Plos::BaseResolver

  def resolve
    unresolved_references.each do |index, text|
      info = {
          ref_text: text,
      }
      root.set_result(index, info )
    end
  end

end