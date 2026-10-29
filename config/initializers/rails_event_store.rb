require "rails_event_store"
require "aggregate_root"
require "arkency/command_bus"

Rails.configuration.to_prepare do
  Rails.configuration.event_store = RailsEventStore::JSONClient.new
  Rails.configuration.command_bus = Arkency::CommandBus.new
  Rails.configuration.command_bus.register(Voting::RecordVoteCommand, lambda do |command|
    Voting::RecordVote.new.call(event_id: command.event_id, user_id: command.user_id, value: command.value)
  end)
  Rails.configuration.command_bus.register(Events::ImportEventsCommand, ->(_command) { Events::ImportEvents.new.call })
  ApplicationSubscriptions.call(Rails.configuration.event_store)
end
