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

class PaperInfoCache < ActiveRecord::Base

  validates :identifier, presence:true
  validates :info_json,  presence:true

  def self.find_by_identifier(type, identifier)
    self.where(identifier:full_identifier(type, identifier)).first
  end

  def self.update(type, identifier, info)
    cache = find_by_identifier(type, identifier)

    if cache
      cache.update_attributes(info: info)
    else
      self.create!(identifier: full_identifier(type, identifier),
                   info:       info                              )
    end
  end

  def info
    @info ||= info_json.present? ? JSON.parse(info_json, symbolize_names:true) : {}
  end

  def info=(value)
    @info = nil
    self.info_json = JSON.generate(value)
  end

  protected

  def self.full_identifier(type, identifier)
    "#{type}:#{identifier}"
  end

end
