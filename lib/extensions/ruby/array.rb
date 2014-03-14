class Array

  def median
    copy = self.compact
    return nil if copy.empty?

    copy.sort!

    len = copy.length
    if len.odd?
      copy[ (len-1)/2 ].to_f
    else
      (copy[(len - 1) / 2] + copy[len / 2]) / 2.0
    end
  end

  def symbolize_keys_recursive!
    each do |v|
      case v
        when Hash, Array then v.symbolize_keys_recursive!
      end
    end

    self
  end

end