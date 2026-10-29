module Events
  class ImportEvents
    def initialize
      @store = Rails.configuration.event_store
    end

    def call
      attributes_list = Billetto::Client.new.fetch_events
      Event.transaction do
        attributes_list.each do |attributes|
          event = Event.find_or_initialize_by(billetto_id: attributes.fetch(:billetto_id))
          event.assign_attributes(attributes.except(:billetto_id))
          changed = event.has_changes_to_save?
          event.save!
          if changed
            domain_event = Events::EventImported.new(data: attributes.merge(event_id: event.id, starts_at: event.starts_at.iso8601))
            domain_event.stream_names.each { |stream_name| @store.publish(domain_event, stream_name: stream_name) }
          end
        end
      end
    end
  end
end
