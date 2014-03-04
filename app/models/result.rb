class Result < ActiveRecord::Base
  before_create :set_token
  before_save   :normalize_fields

  validates :query, presence:true
  validates :limit, presence:true, numericality: { only_integer: true, less_than_or_equal_to:500 }

  def self.find_or_new(params)
    find_params = params.dup
    find_params[:query] = find_params[:query].try(:downcase)

    self.where(find_params).first || self.new(params)
  end

  def self.for_token(token)
    self.where(token:token).first
  end

  private

  def set_token
    token = SecureRandom.urlsafe_base64(nil, false)
  end

  def normalize_fields
    query ||= query.downcase
  end

end
