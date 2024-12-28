Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  devise_scope :user do
    root "users/sessions#new"
  end

  devise_for :users, controllers: { sessions: "users/sessions" }

  namespace :api do
    namespace :v1 do
      resources :companies, only: %i[index show create] do
        post :import, on: :collection
      end
    end
  end
end
