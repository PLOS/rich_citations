class_path = File.join(Rails.root, 'xslt', '*')
xslt_path = File.join(Rails.root, 'xslt', 'articleTransform-v3.xsl')
catalog_path = File.join(Rails.root, 'xslt', 'catalog.xml')
xml_file = Tempfile.new('citation')
xml_file << @xml
IO.popen("java -cp '#{class_path}' net.sf.saxon.Transform -catalog:#{catalog_path} -s:#{xml_file.path} -xsl:#{xslt_path} journalBaseURL=#{@paper.journal_url}") {|xslt_io|
  return xslt_io.read
}
