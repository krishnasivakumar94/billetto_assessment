class EventsController < ApplicationController
  def index
    @events = Event.where("starts_at >= ?", Time.current).order(:starts_at)
    @vote_counts = Vote.where(event_id: @events).group(:event_id, :value).count
  end

  def vote
    user_id = clerk_user_id
    if user_id.blank?
      return redirect_to(root_path, alert: "Sign in with Clerk before voting.") if request.format.html?
      return head :unauthorized
    end

    event = Rails.configuration.command_bus.call(
      Voting::RecordVoteCommand.new(event_id: params[:id], user_id: user_id, value: params.require(:value))
    )
    return redirect_to(root_path, notice: "Your vote has been recorded.") if request.format.html?

    render json: { upvotes: event.upvotes, downvotes: event.downvotes }
  rescue ActiveRecord::RecordNotFound
    head :not_found
  rescue ArgumentError, ActionController::ParameterMissing
    head :unprocessable_content
  end
end
