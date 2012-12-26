require_dependency "importer_extension/application_controller"

module ImporterExtension
  class FileImportsController < ApplicationController
    before_filter :get_main_app_models, only: [:new]
    
    def index
    end
    
    def new
      # Object def types
    end
    
    def import
      klazz = params[:object_definition].to_s
      klazz = "#{::AP::ImporterExtension::Importer::Config.instance.latest_version.upcase}::#{klazz}".constantize
      
      @file_import = ::ImporterExtension::FileImport.new
      status = @file_import.import(params[:file], klazz)
      if status
        @file_import.save
        
        redirect_to @file_import
      else
        render action: "new"
      end
    end
    
protected

    def get_main_app_models
      @available_object_definitions = "#{::AP::ImporterExtension::Importer::Config.instance.latest_version.upcase}".constantize.constants
      if @available_object_definitions.blank?
        version = ::AP::ImporterExtension::Importer::Config.instance.latest_version
        Dir.glob(Rails.root.join("app", "models", version, "*")).each do |f|
          "::#{version.upcase}::#{File.basename(f, '.*').camelize}".constantize.name 
        end

        @available_object_definitions = "#{::AP::ImporterExtension::Importer::Config.instance.latest_version.upcase}".constantize.constants
      end
    end

  end
end
