class Transaction < ApplicationRecord
  belongs_to :user
  belongs_to :session, optional: true
  
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :transaction_type, presence: true, inclusion: { in: ['credit', 'debit'] }
  validates :status, presence: true, inclusion: { in: ['pending', 'completed', 'failed'] }
  validates :paystack_reference, uniqueness: true, allow_nil: true

  def record_metadata(data, ip = nil)
    self.metadata = data.to_json if data
    self.ip_address = ip if ip
    save
  end
end
