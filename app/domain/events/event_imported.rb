module Events
  class EventImported < RubyEventStore::Event
    SCHEMA = { event_id: Integer, billetto_id: String, title: String, starts_at: String, image_url: String, description: String, billetto_url: String }.freeze

    def stream_names
      ["Event$#{data.fetch(:event_id)}"]
    end
  end
end
