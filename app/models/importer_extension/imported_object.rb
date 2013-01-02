module ImporterExtension
  class ImportedObject
    include ActiveModel::MassAssignmentSecurity
    include Mongoid::Document
    include Mongoid::Timestamps
    
    field :imported_object_definition_id, type: String
    
    embedded_in :file_import, class_name: "ImporterExtension::FileImport"
    
  end
end