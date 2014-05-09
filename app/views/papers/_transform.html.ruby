saxon_jar_path = File.join(Rails.root, 'xslt', 'saxon9he.jar')
xslt_path = File.join(Rails.root, 'xslt', 'articleTransform-v3.xsl')
xml_file = Tempfile.new('citation')
xml_file << Plos::Api.document(@doi)
IO.popen("java -jar #{saxon_jar_path} -s:#{xml_file.path} -xsl:#{xslt_path} journalBaseURL=#{@paper.journal_url}") {|xslt_io|
  return xslt_io.read
}
