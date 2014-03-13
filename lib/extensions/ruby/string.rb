class String

  def word_count
    words = strip.split(/\s+/)

    non_word= /\A\W*\z/
    words.count do |w|
      w !~ non_word
    end
  end

end