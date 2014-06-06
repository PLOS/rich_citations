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
