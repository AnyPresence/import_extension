ImporterExtension::Engine.routes.draw do
  get 'settings' => 'settings#settings'
  
  resources :file_imports do
    collection { post :import }
  end
end
