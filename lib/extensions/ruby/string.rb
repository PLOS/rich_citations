class String

  def word_count
    words = strip.split(/\s+/)

    non_word= /\A\W*\z/
    words.count do |w|
      w !~ non_word
    end
  end

  def truncate_beginning(truncate_at, options = {})
    return dup unless length > truncate_at

    omission = options[:omission] || '...'
    start_with_room_for_omission = length - truncate_at + omission.length
    right = self[start_with_room_for_omission, length]

    if options[:separator]
      parts = right.split(options[:separator], 2)
      right = parts.second.lstrip if parts.length > 1
    end

    "#{omission}#{right}"
  end


end