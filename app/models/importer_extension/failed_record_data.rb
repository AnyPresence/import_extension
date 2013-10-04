module ImporterExtension
  class FailedRecordData
    include ActiveModel::MassAssignmentSecurity
    include Mongoid::Document
  
    attr_accessible :field_name, :field_value, :record_errors
  
    field :field_name, type: String
    field :field_value, type: String
  
    embeds_many :record_errors, :class_name => "ImporterExtension::FailedRecordError"
  
    def error_summary
      self.record_errors.map { |error| error.error_description }.join(", ")
    end
  end
end