require_dependency "importer_extension/application_controller"

module ImporterExtension
  class FileImportsController < ApplicationController
    before_filter :get_main_app_models, only: [:new, :import]
    
    def index; end
    
    def new; end
    
    def show
       @file_import = ::ImporterExtension::FileImport.find(params[:id])
    end
    
    def check_file
      if File.extname(params[:file]) == ".xml"
        render 'xml' 
      else
        render :nothing => true
      end
    end
    
    def import
      klazz_name = params[:object_definition].to_s
      flash[:notice] = "Please select an object definition"
      if klazz_name.blank?
        render action: "new"
        return
      end
      
      klazz = "#{::AP::ImporterExtension::Importer::Config.instance.latest_version.upcase}::#{klazz_name}".constantize
    
      options = {}
      options[:is_google_spreadsheet] = true unless params[:google_spreadsheet_key].blank?
      
      options[:css_selector] = params[:css_selector]
        
      @file_import = ::ImporterExtension::FileImport.new
      if options[:is_google_spreadsheet]
        file = params[:google_spreadsheet_key]
        options[:google_email] = params[:google_email]
        options[:google_password] = params[:google_password]
        @file_import.filename = file
      else
        file = params[:file]
        @file_import.file = Moped::BSON::Binary.new(:generic, file.read)
        @file_import.filename = file.original_filename
      end
     
      if @file_import.save
        Resque.enqueue(::ImporterExtension::ImporterWorker, {"file_import_id" => @file_import.id, "klazz_name" => klazz.to_s, "options" => options})
        
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
