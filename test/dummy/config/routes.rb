Rails.application.routes.draw do

  mount ImporterExtension::Engine => "/importer_extension"
end
