ImporterExtension::Engine.routes.draw do
  get 'settings' => 'file_imports#new'
   
  resources :file_imports do
    collection { post :import }
  end
end
