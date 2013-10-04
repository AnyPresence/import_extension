module ImporterExtension
  class FailedRecordError
    include ActiveModel::MassAssignmentSecurity
    include Mongoid::Document
  
    field :field_name, type: String
    field :error_description, type: String
  
    embedded_in :failed_record_data, class_name: "ImporterExtension::FailedRecordData"
  end
end