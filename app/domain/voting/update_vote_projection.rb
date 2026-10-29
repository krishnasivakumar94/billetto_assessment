module Voting
  class UpdateVoteProjection
    def call(event)
      Vote.upsert(
        {
          event_id: event.data.fetch(:event_id),
          user_id: event.data.fetch(:user_id),
          value: event.data.fetch(:value),
          created_at: Time.current,
          updated_at: Time.current
        },
        unique_by: [:event_id, :user_id]
      )
    end
  end
end
