module ImporterExtension
  class FileImport
    include ActiveModel::MassAssignmentSecurity
    include Mongoid::Document
    include Mongoid::Timestamps
    
    EXTENSION_REGEX = /__.*_perform/

    attr_accessible :file_type, :filename, :name

    field :file, type: Moped::BSON::Binary
    field :filename, type: String, default: ""
    field :object_definition_name, type: String
    
    embeds_many :imported_objects, :class_name => "ImporterExtension::ImportedObject"
    
    SPREADSHEET_FILE_EXTS = [".csv", ".xls", ".xlsx"]
    XML_FILE_EXTS = [".xml"]
    
    # Imports the file.
    def import(file, klazz, options={})
      self.object_definition_name = klazz.to_s
      options = HashWithIndifferentAccess.new(options)
      
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
      case File.extname(filename)
      when ".csv" then Csv.new(file.path, nil, :ignore)
      when ".xls" then Excel.new(file.path, nil, :ignore)
      when ".xlsx" then Excelx.new(file.path, nil, :ignore)
      else raise "unknown file type: #{filename}"
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
        ENV["GOOGLE_MAIL"] = options[:google_email]
        ENV["GOOGLE_PASSWORD"] = options[:google_password]
        spreadsheet = Google.new(filename)
      else
        spreadsheet = open_spreadsheet(file)
      end
      header = spreadsheet.row(1)
      (2..spreadsheet.last_row).each do |i|
        row = Hash[[header, spreadsheet.row(i)].transpose]
        obj = klazz.find(:id => row["id"])
        obj = klazz.new if obj.blank?
        obj.attributes = row.to_hash.slice(*klazz.accessible_attributes)
        save_object_without_callbacks(obj)
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
        save_object_without_callbacks(obj)
        self.imported_objects << ::ImporterExtension::ImportedObject.new(imported_object_definition_id: obj.id)
        count += 1
      end
      
      count
    end
    
    def save_object_without_callbacks(obj)
      # ActiveRecord ORM should respond to this
      if obj.class.respond_to?(:skip_callback)        
        # Find callbacks
        ["save", "create", "update"].each do |callback_type|
          callbacks = obj.class.send("_#{callback_type}_callbacks").select{|callback| callback.kind.eql?(:after) }
          #reapply_callbacks[callback_type] = []
          callbacks.each do |callback|
            next unless callback.filter.to_s.match(EXTENSION_REGEX)
            Rails.logger.debug "Skip callback: #{callback.filter}"
            obj.define_singleton_method(callback.filter) { p "Not doing anything..."}
          end
        end
        # Finally save the object
        obj.save!
        
      else
        # Assume that we're dealing with Datamapper ORM
        obj.save!
      end
    end
  end
end
