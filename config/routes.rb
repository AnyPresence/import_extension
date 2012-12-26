ImporterExtension::Engine.routes.draw do
  match 'settings' => 'settings#settings'
  
  resources :file_imports do
    collection { post :import }
  end
end
