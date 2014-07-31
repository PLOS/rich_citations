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

describe Processors::CitationGroupSection do
  include Spec::ProcessorHelper

  before do
    refs 'First'
  end

  it "should include the section title" do
    body "<sec><title>Title 1</title>Some text #{cite(1)} More text<sec>"
    expect(result[:groups][0][:section]).to eq('Title 1')
  end

  it "should include the outermost section title" do
    body "<sec><title>Title 1</title>"
    body "<sec><title>Title 2</title>Some text #{cite(1)} More text</sec>"
    body "</sec>"
    expect(result[:groups][0][:section]).to eq('Title 1')
  end

  it "should include the outermost section that has a title" do
    body "<sec>"
    body "<sec><title>Title 2</title>Some text #{cite(1)} More text</sec>"
    body "</sec>"
    expect(result[:groups][0][:section]).to eq('Title 2')
  end

  it "should include nothing if there is no section" do
    body "<p><title>Title 2</title>Some text #{cite(1)} More text</p>"
    expect(result[:groups][0][:section]).to eq('[Unknown]')
  end

  it "should include nothing if the section has no title" do
    body "<sec>Some text #{cite(1)} More text</sec>"
    expect(result[:groups][0][:section]).to eq('[Unknown]')
  end

end
