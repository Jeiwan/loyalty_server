class Pharmacy < ActiveRecord::Base
  before_create :set_single_access_token

  private

  def set_single_access_token
    self.single_access_token = Authlogic::Random.friendly_token
  end
end
