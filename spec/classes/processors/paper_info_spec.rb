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

require 'spec_helper'

describe Processors::PaperInfo do
  include Spec::ProcessorHelper

  it "should have a title" do
    body <<-XML
      <front>
      <article-meta>
      <title-group>
        <article-title>Sexy Faces in a Male Paper Wasp</article-title>
      </title-group>
      </article-meta>
      </front>
    XML
    expect(result[:paper][:title]).to eq('Sexy Faces in a Male Paper Wasp')
  end

  it "should have a word count" do
    body 'here is <b>some</b> text'
    expect(result[:paper][:word_count]).to eq(4)
  end

  it "cleanup the paper object" do
    cleanup(paper:{a:1,b:nil,c:3})
    expect(result[:paper]).to eq(a:1, c:3)
  end

end
