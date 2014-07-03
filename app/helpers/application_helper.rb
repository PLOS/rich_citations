module ApplicationHelper
  def format_author_name_inverted_initials(author)
    if (author[:literal].present?) then
      return author[:literal]
    elsif (author[:given].present? && author[:family].present?)
      initials = author[:given].split(/\s+/).map {|n|
        n[0]
      }.join("").upcase
      return "#{author[:family]} #{initials}"
    else
      return "[unknown]"
    end
  end
  
  def render_paper_authors(paper)
    return paper[:author].map{|a| format_author_name_inverted_initials(a)}.join("; ").html_safe
  end
end
