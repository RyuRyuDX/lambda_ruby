Rails.application.routes.draw do
  resources :videos do
    collection do
      get :fetch_videos
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check

  # root "posts#index"
end
