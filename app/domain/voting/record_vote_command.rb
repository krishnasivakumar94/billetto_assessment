module Voting
  RecordVoteCommand = Struct.new(:event_id, :user_id, :value, keyword_init: true)
end
