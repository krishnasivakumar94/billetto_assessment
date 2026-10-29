module Events
  class VoteRecorded < RubyEventStore::Event
    SCHEMA = { event_id: Integer, user_id: String, value: Integer }.freeze

    def stream_names
      ["Event$#{data.fetch(:event_id)}"]
    end
  end
end
