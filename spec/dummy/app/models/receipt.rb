class Receipt < ActiveRecord::Base

  belongs_to :cashbox_operation

  before_create :set_uuid

  private

  def set_uuid
    return if uuid.present?
    self.uuid = SecureRandom.uuid
  end
end
