Rails.application.routes.draw do
  get 'authorization/get_ticket', as: :get_ticket
  get 'authorization/set_cookies', as: :set_cookies

  get 'home/index'

  devise_for :users
  root 'home#index'
end
