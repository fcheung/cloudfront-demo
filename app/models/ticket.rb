class Ticket < ActiveRecord::Base
  belongs_to :user
  before_create :set_token

  def set_token
    self.token = SecureRandom.urlsafe_base64(40)
  end
end
