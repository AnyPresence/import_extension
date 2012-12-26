module ImporterExtension
  class FileImport
    include ActiveModel::MassAssignmentSecurity
    include Mongoid::Document
    include Mongoid::Timestamps
    
    attr_accessible :file_type, :name

    field :imported_objects, type: Array, default: []
    field :object_definition_name, type: String
    
    SPREADSHEET_FILE_EXTS = [".csv", ".xls", ".xlsx"]
    
    def import(file, klazz)
      self.object_definition_name = klazz.to_s
      
      if SPREADSHEET_FILE_EXTS.include?(File.extname(file.original_filename))
        import_spreadsheet(file, klazz)
        return true
      else
        import_text_file(file, klazz)
        return true
      end
    end
    
    def open_spreadsheet(file)
      case File.extname(file.original_filename)
      when ".csv" then Csv.new(file.path, nil, :ignore)
      when ".xls" then Excel.new(file.path, nil, :ignore)
      when ".xlsx" then Excelx.new(file.path, nil, :ignore)
      else raise "unknown file type: #{file.original_filename}"
      end
    end
    
  protected 
    def import_text_file(file, klazz)
      Rails.logger.info "Importing regular file"
    end
    
    def import_spreadsheet(file, klazz)
      spreadsheet = open_spreadsheet(file)
      header = spreadsheet.row(1)
      (2..spreadsheet.last_row).each do |i|
        row = Hash[[header, spreadsheet.row(i)].transpose]
        obj = klazz.find(:id => row["id"])
        obj = klazz.new if obj.blank?
        obj.attributes = row.to_hash.slice(*klazz.accessible_attributes)
        # TODO: need to have it not invoke callbacks
        obj.save!
        self.imported_objects << obj.id
      end
    end
    
  end
end
