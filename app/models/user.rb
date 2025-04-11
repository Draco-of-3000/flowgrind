class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :trackable

  # Relatonships
  #has_many :sessions, dependent: :destroy
  #has_many :paired_sessions, class_name: 'Session', foreign_key: 'paired_user_id'
  has_many :transactions, dependent: :destroy
  #has_many :paired_requests, foreign_key: 'requester_id', dependent: :destroy
  #has_many :matched_requests, class_name: 'PairedRequest', foreign_key: 'matched_user_id'

  # Validations
  validates :username, presence: true, uniqueness: true
  validates :credits, numericality: { greater_than_or_equal_to: 0 }

  # Callbacks
  after_create :assign_welcome_credits

  # Method to check if user has completed onboarding
  def onboarding_completed?
    self.onboarding_completed
  end

  private

  def assign_welcome_credits
    update(credits: 5.0)
  end
end
