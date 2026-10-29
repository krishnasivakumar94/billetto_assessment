require "rails_helper"

RSpec.describe Events::ImportEvents do
  it "upserts imported events and publishes an event only when data changes" do
    client = instance_double(Billetto::Client)
    allow(Billetto::Client).to receive(:new).and_return(client)
    allow(client).to receive(:fetch_events).and_return([
      { billetto_id: "billetto-new", title: "Live show", starts_at: "2026-12-03T19:00:00Z", image_url: nil, description: "Music", billetto_url: "https://billetto.dk/e/new" }
    ])

    expect {
      Rails.configuration.command_bus.call(Events::ImportEventsCommand.new)
    }.to change(Event, :count).by(1)

    event = Event.find_by!(billetto_id: "billetto-new")
    stream = Rails.configuration.event_store.read.stream("Event$#{event.id}").to_a
    expect(stream.map(&:event_type)).to eq(["Events::EventImported"])

    expect {
      Rails.configuration.command_bus.call(Events::ImportEventsCommand.new)
    }.not_to change { Rails.configuration.event_store.read.stream("Event$#{event.id}").count }
  end
end
