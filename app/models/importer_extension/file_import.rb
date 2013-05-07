require 'nokogiri'
require 'csv'
require 'iconv'
require 'roo'

module ImporterExtension
  class FileImport
    include ActiveModel::MassAssignmentSecurity
    include Mongoid::Document
    include Mongoid::Timestamps
    
    EXTENSION_REGEX = /__.*_perform/
    HEADER_ROW_START = 1

    attr_accessible :file_type, :filename, :name

    field :file, type: Moped::BSON::Binary
    field :filename, type: String, default: ""
    field :object_definition_name, type: String
    field :processed, type: Integer, default: 0
    field :started, type: Boolean, default: false
    field :total, type: Integer
    
    embeds_many :imported_objects, :class_name => "ImporterExtension::ImportedObject"
    
    SPREADSHEET_FILE_EXTS = [".csv", ".xls", ".xlsx"]
    XML_FILE_EXTS = [".xml"]
    
    # Imports the file.
    def import(file, klazz, options={})
      self.object_definition_name = klazz.to_s
      options = HashWithIndifferentAccess.new(options)
      
      begin
        if SPREADSHEET_FILE_EXTS.include?(File.extname(filename)) || options[:is_google_spreadsheet]
          Rails.logger.info("Importing spreadsheet: #{filename}")
          import_spreadsheet(file, klazz, options)
        elsif XML_FILE_EXTS.include?(File.extname(filename))
          Rails.logger.info("Importing xml file: #{filename}")
          import_xml(file, klazz, options)
        else
          import_text_file(file, klazz)
        end
      rescue
        self.ad
      end
      
    end
    
    def check(options={})
      is_valid_ext = !options[:is_google_spreadsheet].blank? || (SPREADSHEET_FILE_EXTS+XML_FILE_EXTS).include?(File.extname(filename))
      if is_valid_ext && XML_FILE_EXTS.include?(File.extname(filename))
        return false if options[:css_selector].blank?
      end
      
      if is_valid_ext && SPREADSHEET_FILE_EXTS.include?(File.extname(filename))
        tempfile = open_file
        begin
          spreadsheet = open_spreadsheet(tempfile)
          header = spreadsheet.row(HEADER_ROW_START)
          ((HEADER_ROW_START+1)..spreadsheet.last_row).each do |i|
            spreadsheet.row(i)
          end
        rescue
          self.errors.add(:base, "Unable to open file: #{$!.message}");
          return false
        ensure
          if !tempfile.blank?
            tempfile.close
            tempfile.unlink
          end
        end
      end
      
      is_valid_ext    
    end
    
  protected 
  
    def open_file
      tempfile = Tempfile.new(self.filename)
      tempfile.binmode
      tempfile.write(self.file.data)
      tempfile.rewind
      tempfile
    end
  
    def open_spreadsheet(file)
      case File.extname(filename)
      when ".csv" then ::Roo::Csv.new(file.path, nil, :ignore)
      when ".xls" then ::Roo::Excel.new(file.path, nil, :ignore)
      when ".xlsx" then ::Roo::Excelx.new(file.path, nil, :ignore)
      else raise "unknown file type: #{filename}"
      end
    end
  
    def import_text_file(file, klazz)
      Rails.logger.info "Importing regular file"
    end
    
    def import_spreadsheet(file, klazz, options={})
      if options[:is_google_spreadsheet]
        ENV["GOOGLE_MAIL"] = options[:google_email]
        ENV["GOOGLE_PASSWORD"] = options[:google_password]
        spreadsheet = ::Roo::Google.new(filename)
      else
        spreadsheet = open_spreadsheet(file)
      end
      header = spreadsheet.row(HEADER_ROW_START)
      
      self.total = spreadsheet.last_row - HEADER_ROW_START
      count = 0
      ((HEADER_ROW_START+1)..spreadsheet.last_row).each do |i|
        row = Hash[[header, spreadsheet.row(i)].transpose]        
        begin
          obj = klazz.find(:id => row["id"])
        rescue
          # OK to ignore...
        end
        obj = klazz.new if obj.blank?
        obj.assign_attributes(row.to_hash.slice(*klazz.accessible_attributes(:"System Admin")), :as => :"System Admin")
        begin
          save_object_without_callbacks(obj)
        rescue
          Rails.logger.error("Not able to save: #{obj.inspect}, error: #{$!.message}")
        end
        count += 1
        self.processed = count
        save if (count % 100) == 0
        
        self.imported_objects << ::ImporterExtension::ImportedObject.new(imported_object_definition_id: obj.id)
      end
      save
    end
    
    def import_xml(file, klazz, options={})
      Rails.logger.info("Importing xml file...")
      doc = ::Nokogiri::XML(file)
      css_selector = options[:css_selector]
      raise "CSS selector needed" if css_selector.blank?
      
      count = 0
      nodeset = doc.css(css_selector)
      self.total = nodeset.size
      nodeset.each do |node|
        attributes = Hash.from_xml(node.to_s)
        begin
          obj = klazz.find(:id => attributes["id"])
        rescue
          # OK to ignore...
        end
        obj = klazz.new if obj.blank?
        obj.assign_attributes(attributes.values.first.slice(*klazz.accessible_attributes(:"System Admin")), :as => :"System Admin")
        begin
          save_object_without_callbacks(obj)
        rescue
          Rails.logger.error("Not able to save: #{obj.inspect}, error: #{$!.message}")
        end
        count += 1
        self.processed = count
        save if (count % 100) == 0
        self.imported_objects << ::ImporterExtension::ImportedObject.new(imported_object_definition_id: obj.id)
      end
      
      save
    end
    
    # Saves the object without hitting extension callbacks.
    #
    # This is done by setting the callback methods to an empty method on the eigenclass
    # so that it only affects the instance.
    def save_object_without_callbacks(obj)
      # ActiveRecord ORM should respond to this
      if obj.class.respond_to?(:skip_callback)        
        # Find callbacks
        ["save", "create", "update"].each do |callback_type|
          callbacks = obj.class.send("_#{callback_type}_callbacks").select{|callback| callback.kind.eql?(:after) }
          callbacks.each do |callback|
            next unless callback.filter.to_s.match(EXTENSION_REGEX)
            Rails.logger.debug "Skip callback: #{callback.filter}"
            obj.define_singleton_method(callback.filter) { p "callback disabled..."}
          end
        end
      end
      
      # Finally save the object. For Datamapper, +save!+ will skip callbacks.
      obj.save!
    end
  end
end
