require "rails_helper"

RSpec.describe Voting::RecordVote do
  let(:event) { events(:one) }

  it "records a vote through the event store projection" do
    expect {
      dispatch_vote(1)
    }.to change { Vote.where(event: event, user_id: "clerk_user").count }.from(0).to(1)

    expect(event.reload.upvotes).to eq(1)
    expect(event.downvotes).to eq(0)
  end

  it "changes an existing user's vote without creating another vote" do
    dispatch_vote(1)

    expect {
      dispatch_vote(-1)
    }.not_to change { Vote.where(event: event, user_id: "clerk_user").count }

    expect(event.reload.upvotes).to eq(0)
    expect(event.downvotes).to eq(1)
  end

  it "rejects values outside upvote and downvote" do
    expect {
      dispatch_vote(0)
    }.to raise_error(ArgumentError, "value must be -1 or 1")
  end

  def dispatch_vote(value)
    Rails.configuration.command_bus.call(Voting::RecordVoteCommand.new(event_id: event.id, user_id: "clerk_user", value: value))
  end
end
