module Voting
  class RecordVote
    def call(event_id:, user_id:, value:)
      event = Event.find(event_id)
      raise ArgumentError, "value must be -1 or 1" unless [-1, 1].include?(value.to_i)

      domain_event = Events::VoteRecorded.new(data: { event_id: event.id, user_id: user_id, value: value.to_i })
      domain_event.stream_names.each do |stream_name|
        Rails.configuration.event_store.publish(domain_event, stream_name: stream_name)
      end
      event
    end
  end
end
