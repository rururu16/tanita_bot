Rails.application.routes.draw do
  root 'linebot#index'
  post '/callback', to: 'linebot#callback'
end
