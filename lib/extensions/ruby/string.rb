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

  def word_truncate(count, omission='...')
    string = self.rstrip
    matches = /\s+/.all_matches(string)
    return string unless matches
    count += 1 if matches.first.begin(0) == 0

    if matches.length >= count
      length = matches[count-1].begin(0) - 1
      string[0..length] + omission
    else
      string
    end
  end

  def word_truncate_beginning(count, omission='...')
    string = self.lstrip
    matches = /\s+/.all_matches(string)
    return string unless matches
    count += 1 if matches.last.end(0) == string.length

    if matches.length >= count
      start = matches[matches.length-count].end(0)
      omission + string[start..length]
    else
      string
    end
  end

end