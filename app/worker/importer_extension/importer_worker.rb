class ::ImporterExtension::ImporterWorker
  @queue = :importer_worker

  def self.perform(klazz_data)
    file_import = ::ImporterExtension::FileImport.find(klazz_data["file_import_id"])
    tempfile = nil
    if !file_import.file.blank?
      tempfile = Tempfile.new(file_import.filename)
      tempfile.binmode
      tempfile.write(file_import.file.data)
      tempfile.rewind
    end
    
    Rails.logger.info("Importing the file with: model => #{klazz_data['klazz_name']}, options => #{klazz_data['options'].inspect}")
    begin
      file_import.import(tempfile, klazz_data["klazz_name"].constantize, klazz_data["options"])
    ensure
      if !tempfile.blank?
        tempfile.close
        tempfile.unlink
      end
    end
  end
end