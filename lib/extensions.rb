class Array

  def median
    return nil if empty?

    sorted = self.sort
    len = sorted.length
    if len.odd?
      sorted[ (len-1)/2 ].to_f
    else
      (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
    end
  end

end