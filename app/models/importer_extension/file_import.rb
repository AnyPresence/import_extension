module ImporterExtension
  class FileImport
    include ActiveModel::MassAssignmentSecurity
    include Mongoid::Document
    include Mongoid::Timestamps
    
    attr_accessible :file_type, :name

    field :object_definition_name, type: String
    
    embeds_many :imported_objects, :class_name => "ImporterExtension::ImportedObject"
    
    SPREADSHEET_FILE_EXTS = [".csv", ".xls", ".xlsx"]
    XML_FILE_EXTS = [".xml"]
    
    # Imports the file.
    def import(file, klazz, options={})
      self.object_definition_name = klazz.to_s

      if options[:is_google_spreadsheet]
        filename = file
      else
        filename = file.original_filename if file.respond_to?(:original_filename)
      end
      
      count = 0
      if SPREADSHEET_FILE_EXTS.include?(File.extname(filename)) || options[:is_google_spreadsheet]
        count = import_spreadsheet(file, klazz, options)
      elsif XML_FILE_EXTS.include?(File.extname(filename))
        count = import_xml(file, klazz, options)
      else
        count = import_text_file(file, klazz)
      end
      
      count
    end
    
  protected 
  
    def open_spreadsheet(file)
      case File.extname(file.original_filename)
      when ".csv" then Csv.new(file.path, nil, :ignore)
      when ".xls" then Excel.new(file.path, nil, :ignore)
      when ".xlsx" then Excelx.new(file.path, nil, :ignore)
      else raise "unknown file type: #{file.original_filename}"
      end
    end
  
    def import_text_file(file, klazz)
      count = 0
      Rails.logger.info "Importing regular file"
      count
    end
    
    def import_spreadsheet(file, klazz, options={})
      count = 0
      if options[:is_google_spreadsheet]
        ENV["GOOGLE_EMAIL"] = options[:google_email]
        ENV["GOOGLE_PASSWORD"] = options[:google_password]
        spreadsheet = Google.new(file)
      else
        spreadsheet = open_spreadsheet(file)
      end
      header = spreadsheet.row(1)
      (2..spreadsheet.last_row).each do |i|
        row = Hash[[header, spreadsheet.row(i)].transpose]
        obj = klazz.find(:id => row["id"])
        obj = klazz.new if obj.blank?
        obj.attributes = row.to_hash.slice(*klazz.accessible_attributes)
        # TODO: need to have it not invoke callbacks
        obj.save!
        self.imported_objects << ::ImporterExtension::ImportedObject.new(imported_object_definition_id: obj.id)
        count += 1
      end
      
      count
    end
    
    def import_xml(file, klazz, options={})
      count = 0
      
      doc = Nokogiri::XML(file)
      css_selector = options[:css_selector]
      raise "CSS selector needed" if css_selector.blank?
      
      doc.css(css_selector).each do |node|
        attributes = Hash.from_xml(node.to_s)
        obj = klazz.find(:id => attributes["id"])
        obj = klazz.new if obj.blank?
        obj.attributes = attributes.slice(*klazz.accessible_attributes)
        obj.save!
        self.imported_objects << ::ImporterExtension::ImportedObject.new(imported_object_definition_id: obj.id)
        count += 1
      end
      
      count
    end
    
  end
end
