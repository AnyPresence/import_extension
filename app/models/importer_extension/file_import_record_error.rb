module ImporterExtension
  class FileImportRecordError
    include ActiveModel::MassAssignmentSecurity
    include Mongoid::Document
    
    attr_accessible :record_number, :data

    field :record_number, type: Integer
    
    embeds_many :data, :class_name => "ImporterExtension::FailedRecordData"
    
    embedded_in :file_import, class_name: "ImporterExtension::FileImport"
    
    def initialize(data, record_errors, args = nil, options = nil)
      super(args, options)
      
      data.each do |k,v|
        self.data << ImporterExtension::FailedRecordData.new(field_name: k.to_s, field_value: v.to_s)
      end
      
      record_errors.each do |k,v|
        failed_data = self.data.where(field_name: k.to_s).first
        if failed_data
          failed_data.record_errors << ImporterExtension::FailedRecordError.new(field_name: k.to_s, error_description: v.to_s)
        else
          new_data = ImporterExtension::FailedRecordData.new(field_name: k.to_s)
          new_data.record_errors << ImporterExtension::FailedRecordError.new(field_name: k.to_s, error_description: v.to_s)
          self.data << new_data
        end
      end
    end
    
  end
    
end