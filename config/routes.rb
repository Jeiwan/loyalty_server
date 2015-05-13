Loyalty::Engine.routes.draw do
  resources :cards, param: :number do
    collection do
      post :upload
    end
    member do
      put :block
      put :unblock
    end
  end

  resources :purchases
  resources :gifts
  resources :certificates

  root 'dashboard#index'

  namespace :api do
    resources :cards_certificates, param: :number, only: [] do
      member do
        get :check
      end
    end

    resources :cards, param: :number, only: [] do
      member do
        get :balance
        put :activate
        get :check_for_return
      end
    end

    resources :certificates, param: :number, only: [] do
      member do
        get :check
        get :check_pin_code
        get :apply
      end
    end

    resources :purchases, only: [:create] do
      collection do
        put :commit
        put :rollback
        put :demand_gift
        get :check_threshold
      end
    end
  end
end
