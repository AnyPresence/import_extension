require 'test_helper'

module ImporterExtension
  class FileImportTest < ActiveSupport::TestCase
    
    test "import xls spreadsheet" do
      ::V1::Outage.any_instance.expects(:save!).times(2)
      
      filename = File.join(".", "test", "support", "dummy_file.xls")
      File.open(filename) do |file|
        file_import = FileImport.new
        file_import.stubs(:filename).returns("#{filename}")
        file_import.send(:import_spreadsheet, file, ::V1::Outage)
      end
    end
    
    test "import xlsx spreadsheet" do
      ::V1::Outage.any_instance.expects(:save!).times(2)
      
      filename = File.join(".", "test", "support", "dummy_file.xlsx")
      File.open(filename) do |file|
        file_import = FileImport.new
        file_import.stubs(:filename).returns("#{filename}")
        file_import.send(:import_spreadsheet, file, ::V1::Outage)
      end
    end
    
    test "import csv spreadsheet" do
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
    
    test "import xml file" do      
      f = Tempfile.new("xml")
      xml = <<-RUBY
        <?xml version="1.0" encoding="UTF-8"?>
        <v1-outages>
          <outage>
            <name>womp</name>
            <task_id>1</task_id>
          </outage>
          <outage>
            <name>eep</name>
            <task_id>1</task_id>
          </outage>
          <outage>
            <name>cake</name>
            <task_id>1</task_id>
          </outage>
        </v1-outages>
      RUBY
      
      f.write(xml)
      file_import = FileImport.new
      file_import.stubs(:filename).returns("#{f.path}.xml")
      f.rewind
      file_import.send(:import_xml, f, ::V1::Outage, {:css_selector => "outage"})
      f.close
      f.unlink
      
      assert_not_nil(::V1::Outage.where(:name => "cake").first)
    end
    
  end
end
