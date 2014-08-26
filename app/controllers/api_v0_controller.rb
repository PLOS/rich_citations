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

class ApiV0Controller < ApplicationController
  def paper
    id = params[:id]
    case id
    when %r{^http://dx.doi.org/10.1371/}
      doi = Id::Doi.extract(params[:id])
      # TODO : combine with code in papers controller
      paper = PaperResult.find_or_new_for_doi(doi)
      if paper.should_start_analysis?
        paper.start_analysis!
        paper.save
      end
      response.content_type = Mime::JSON
      headers['Content-Disposition'] = %Q{attachment; filename="#{paper.doi}.json"} unless params[:inline]
      result = paper.ready? ? paper.result : ''
      status = paper.ready? ? :ok : :created
      render(json: result, status: status)

      @paper = PaperResult.find_or_new_for_doi(doi)
    else
      render status: 404, text: ''
    end
  end
end
