# coding: utf-8
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

describe Processors::CitationGroupContext do
  include Spec::ProcessorHelper

  before do
    refs 'First', 'Second', 'Third', 'Fourth', 'Fifth', 'Sixth'
  end

  it "should provide citation context" do
    body "Some text #{cite(1)} More text"
    expect(result[:groups][0][:context]).to eq(citation:    "[1]",
                                               text_before: "Some text ",
                                               text_after:  " More text",
                                              )
  end

  it "should provide the correct text for a group with multiple references context" do
    body "  Some text #{cite(1)}, #{cite(3)} - #{cite(5)} More text  "
    expect(result[:groups][0][:context]).to eq(citation:    "[1], [3] - [5]",
                                               text_before: "Some text ",
                                               text_after:  " More text",
                                              )
  end

  it "should include truncation" do
    before = (1..25).to_a.reverse.join(" ")
    after  = (1..15).to_a.join(" ")
    body "#{before} #{cite(1)} #{after}."
    expected_before = (1..20).to_a.reverse.join(" ")+' '
    expected_after  = ' '+(1..10).to_a.join(" ")
    expect(result[:groups][0][:context]).to eq(citation:         "[1]",
                                               truncated_before: true,
                                               truncated_after:  true,
                                               text_before:      expected_before,
                                               text_after:       expected_after,
                                              )
  end

  it "should be limited to the nearest section" do
    body "<sec>abc<sec>"
    body "Some text #{cite(1)} More text"
    body "</sec>def</sec>"
    expect(result[:groups][0][:context]).to eq(citation:   "[1]",
                                               text_after: " More text",
                                               text_before: "Some text "
                                            )
  end

  it "should be limited to the nearest paragraph" do
    body "<sec>abc<P>"
    body "Some text #{cite(1)} More text"
    body "</P>def</sec>"
    expect(result[:groups][0][:context]).to eq(citation:   "[1]",
                                               text_after: " More text",
                                               text_before: "Some text "
                                              )

  end

end
