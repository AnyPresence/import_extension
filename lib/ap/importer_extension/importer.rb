require 'singleton'

module AP
  module ImporterExtension
    module Importer

       
      class Config
        include Singleton
        
        attr_accessor :latest_version, :configuration
      end
      
    end
  end
end