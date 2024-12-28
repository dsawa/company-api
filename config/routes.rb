Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  namespace :api do
    namespace :v1 do
      resources :companies, only: %i[index show create] do
        post :import, on: :collection
      end
    end
  end
end
