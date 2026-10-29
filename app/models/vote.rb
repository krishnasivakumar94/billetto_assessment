class Vote < ApplicationRecord
  belongs_to :event
  validates :user_id, presence: true
  validates :user_id, uniqueness: { scope: :event_id }
  validates :value, inclusion: { in: [-1, 1] }
end
