require 'test_helper'

module ImporterExtension
  class FileImportTest < ActiveSupport::TestCase
    
    test "import spreadsheet" do
      ::V1::Outage.any_instance.expects(:save!).times(2)
      
      f = Tempfile.new("spreadsheet")
      f.write("name,description\ntest0,desc0\ntest1,desc1\n")
      file_import = FileImport.new
      file_import.stubs(:filename).returns("#{f.path}.csv")
      f.close
      file_import.send(:import_spreadsheet, f, ::V1::Outage)
      f.unlink
    end
    
    test "save without callbacks" do 
      outage = ::V1::Outage.new
      outage.expects(:__sms_on_save_perform).never
      file_import = FileImport.new
      file_import.send(:save_object_without_callbacks, outage)
    end
    
  end
end
