class Hash

  # deep_symbolize_keys does not handle arrays
  def symbolize_keys_recursive!
    symbolize_keys!

    each do |v|
      v.try(:symbolize_keys_recursive!)
    end

    self
  end

end