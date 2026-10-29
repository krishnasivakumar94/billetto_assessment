class ApplicationSubscriptions
  def self.call(event_store)
    event_store.subscribe(Voting::UpdateVoteProjection.new, to: [Events::VoteRecorded])
    event_store.subscribe_to_all_events(RailsEventStore::LinkByEventType.new)
    event_store.subscribe_to_all_events(RailsEventStore::LinkByCorrelationId.new)
    event_store.subscribe_to_all_events(RailsEventStore::LinkByCausationId.new)
  end
end
