class Regexp

  def all_matches(string)
    matches = []
    start   = 0

    start = 0
    while matchdata = self.match(string, start)
      matches << matchdata
      start = matchdata.end(0)
    end

    matches.presence
  end

end