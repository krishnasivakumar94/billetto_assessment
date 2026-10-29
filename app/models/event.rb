class Event < ApplicationRecord
  has_many :votes, dependent: :delete_all

  validates :billetto_id, presence: true, uniqueness: true
  validates :title, :starts_at, presence: true

  def upvotes
    votes.where(value: 1).count
  end

  def downvotes
    votes.where(value: -1).count
  end
end
