Event.find_or_create_by!(billetto_id: "sample-theatre-2026") do |event|
  event.title = "Sample theatre event"
  event.starts_at = Time.zone.parse("2026-12-01 19:30")
  event.description = "Sample event record for the local assessment demo. Not imported from Billetto."
end
