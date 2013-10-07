require 'test_helper'

module ImporterExtension
  class FileImportTest < ActiveSupport::TestCase

    def setup
      ::V1::Contact.destroy_all
    
      @contacts_csv = <<CSV
name,email_address,phone_number,description,priority
"Jones, Fred","fred.jones@gmail.com",(877) 241-LUNA,"Jonesie, you're my hero!",1
"Jones, Mike","mike.jones@gmail.com",,Son of a Jones,
"Pea Tear Gryphon",,,,
,,,,
CSV

      @invalid_contacts_csv = <<CSV
name,email_address,phone_number,description,priority
"Jones, Fred","fred.jones@gmail.com",(877) 241-LUNA,"Jonesie, you're my hero!",1
,"mike.jones@gmail.com",,Son of a Jones,
"Pea Tear Gryphon",,,,
CSV

      @invalid_contacts_xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>      
<contacts>
  <contact>
    <name>Jones, Fred</name>
    <email_address>fred.jones@gmail.com</email_address>
    <phone_number>(877) 241-LUNA</phone_number>
    <description>Jonesie, you're my hero!</description>
    <priority>1</priority>
  </contact>
  <contact>
    <email_address>mike.jones@gmail.com</email_address>
    <description>Son of a Jones</description>
  </contact>
  <contact>
    <name>Pea Tear Gryphon</name>
  </contact>
</contacts>
XML

    end
    
    test "import invalid field data from XML" do
      f = Tempfile.new("tempxml")

      f.write(@invalid_contacts_xml)
      file_import = FileImport.new
      file_import.stubs(:filename).returns("#{f.path}.xml")
      f.rewind
      file_import.send(:import_xml, f, ::V1::Contact, {:css_selector => "contact"})
      f.close
      f.unlink
      
      assert_equal 1, file_import.failed_record_count
      failed_record = file_import.failed_records.first
      assert_equal 3, failed_record.data.size
      data = failed_record.data.where(field_name: "name").first
      assert_equal "name", data.field_name
      assert data.field_value.blank?
      assert_equal 1, data.record_errors.size
      error = data.record_errors.first
      assert_equal error.field_name, "name"
      assert_equal "can't be blank", error.error_description
      
      assert_equal 2, ::V1::Contact.all.size
    end
    
    test "import invalid field data from CSV" do
      f = Tempfile.new("spreadsheet")

      f.write(@invalid_contacts_csv)
      file_import = FileImport.new
      file_import.stubs(:filename).returns("#{f.path}.csv")
      f.close
      file_import.send(:import_spreadsheet, f, ::V1::Contact)
      f.unlink
      
      assert_equal 1, file_import.failed_record_count
      failed_record = file_import.failed_records.first
      assert_equal 5, failed_record.data.size
      data = failed_record.data.where(field_name: "name").first
      assert_equal "name", data.field_name
      assert data.field_value.blank?
      assert_equal 1, data.record_errors.size
      error = data.record_errors.first
      assert_equal error.field_name, "name"
      assert_equal "can't be blank", error.error_description
      
      assert_equal 2, ::V1::Contact.all.size
    end
  
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
    
    test "import csv should not import a record that contains nothing but nil values" do
      f = Tempfile.new("spreadsheet")

      f.write(@contacts_csv)
      file_import = FileImport.new
      file_import.stubs(:filename).returns("#{f.path}.csv")
      f.close
      file_import.send(:import_spreadsheet, f, ::V1::Contact)
      f.unlink
      
      assert_equal 3, ::V1::Contact.all.size
    end

    test "import csv should treat records containing the empty string as nils" do
      f = Tempfile.new("spreadsheet")

      f.write(@contacts_csv)
      file_import = FileImport.new
      file_import.stubs(:filename).returns("#{f.path}.csv")
      f.close
      file_import.send(:import_spreadsheet, f, ::V1::Contact)
      f.unlink
            
      mike = ::V1::Contact.find_by(name: "Jones, Mike")
      assert_equal "Jones, Mike", mike.name
      assert_equal "mike.jones@gmail.com", mike.email_address
      assert_nil mike.phone_number
      assert_equal "Son of a Jones", mike.description
      assert_nil mike.priority
      
      peter_griffin = ::V1::Contact.find_by(name: "Pea Tear Gryphon")
      assert_equal "Pea Tear Gryphon", peter_griffin.name
      assert_nil peter_griffin.email_address
      assert_nil peter_griffin.phone_number
      assert_nil peter_griffin.description
      assert_nil peter_griffin.priority
    end

    test "import csv should not delimit on commas contained within quotes" do
      f = Tempfile.new("spreadsheet")

      f.write(@contacts_csv)
      file_import = FileImport.new
      file_import.stubs(:filename).returns("#{f.path}.csv")
      f.close
      file_import.send(:import_spreadsheet, f, ::V1::Contact)
      f.unlink
            
      fred = ::V1::Contact.find_by(name: "Jones, Fred")
      assert_equal "Jones, Fred", fred.name
      assert_equal "fred.jones@gmail.com", fred.email_address
      assert_equal "(877) 241-LUNA", fred.phone_number
      assert_equal "Jonesie, you're my hero!", fred.description
      assert_equal 1, fred.priority
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
    
    test "save with callbacks" do
      outage = ::V1::Outage.new
      outage.expects(:__sms_on_save_perform).once
      file_import = FileImport.new
      options = { run_callbacks: true }
      file_import.send(:save_object, outage, options)
    end
    
    test "save without callbacks" do 
      outage = ::V1::Outage.new
      outage.expects(:__sms_on_save_perform).never
      file_import = FileImport.new
      file_import.send(:save_object, outage)
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
