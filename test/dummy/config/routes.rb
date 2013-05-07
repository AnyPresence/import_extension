Rails.application.routes.draw do
  namespace :api do
    mount ImporterExtension::Engine => "/importer_extension", :as => "importer_extension"
  end
  
end
