require "rails_helper"

RSpec.describe Event, type: :model do
  it "requires a Billetto id, title and start time" do
    event = described_class.new

    expect(event).not_to be_valid
    expect(event.errors.attribute_names).to include(:billetto_id, :title, :starts_at)
  end

  it "keeps the user's vote unique for an event" do
    event = events(:one)
    Vote.create!(event: event, user_id: "clerk_user", value: 1)

    expect(Vote.new(event: event, user_id: "clerk_user", value: -1)).not_to be_valid
  end
end
