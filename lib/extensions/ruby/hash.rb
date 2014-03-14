class Hash

  def symbolize_keys_recursive!
    symbolize_keys!

    each do |v|
      case v
        when Hash, Array then v.symbolize_keys_recursive!
      end
    end

    self
  end

end