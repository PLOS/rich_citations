# Copyright (c) 2014 Public Library of Science

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

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

  def word_truncate_ending(count)
    string = self.rstrip
    matches = /\s+/.all_matches(string)
    return string unless matches
    count += 1 if matches.first.begin(0) == 0

    if matches.length >= count
      length = matches[count-1].begin(0) - 1
      [ string[0..length], true ]
    else
      [ string, false ]
    end
  end

  def word_truncate_beginning(count)
    string = self.lstrip
    matches = /\s+/.all_matches(string)
    return string unless matches
    count += 1 if matches.last.end(0) == string.length

    if matches.length >= count
      start = matches[matches.length-count].end(0)
      [ string[start..length], true ]
    else
      [ string, false ]
    end
  end

end
