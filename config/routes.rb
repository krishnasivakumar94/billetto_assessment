Rails.application.routes.draw do
  mount RailsEventStore::Browser => '/res' if Rails.env.development?

  get "up" => "rails/health#show", as: :rails_health_check
  root "events#index"
  post "events/:id/vote", to: "events#vote", as: :event_vote

end
