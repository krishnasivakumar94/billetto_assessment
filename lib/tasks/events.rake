namespace :events do
  desc "Seed the local sample event and ensure it has one demo upvote"
  task seed_preview: :environment do
    Rake::Task["db:seed"].invoke
    event = Event.find_by!(billetto_id: "sample-theatre-2026")
    unless Vote.exists?(event: event, value: 1)
      Vote.create!(event: event, user_id: "preview-demo-voter", value: 1)
    end
    puts "Preview event ready (#{Vote.where(event: event, value: 1).count} upvote(s); sample data only)"
  end

  desc "Import public events from the configured Billetto endpoint"
  task import: :environment do
    Rails.configuration.command_bus.call(Events::ImportEventsCommand.new)
    puts "Billetto event import complete"
  rescue Billetto::Client::Error => error
    warn "Billetto event import failed: #{error.message}"
    exit 1
  end
end
