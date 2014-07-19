class Nokogiri::XML::Node

  def to_inner_xml(*args)
    children.to_xml(*args)
  end

end