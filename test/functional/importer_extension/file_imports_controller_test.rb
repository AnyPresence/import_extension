require 'test_helper'

module ImporterExtension
  class FileImportsControllerTest < ActionController::TestCase
    setup do
      class ActionController::Base
        def authenticate_admin! ; end
      end
    end
    
    test "should fail with bad spreadsheet" do
      tempfile = Tempfile.new(["dummy_file", ".csv"])
      data = <<-TEXT
      :{"type",name
      cat
      hello
      TEXT
      
      begin
        tempfile.write(data)
        tempfile.rewind
        tempfile
        file = Rack::Test::UploadedFile.new(tempfile.path, "text/csv")
        @controller.stubs(:render)
        post :import, object_definition: "Outage", file: file, use_route: :importer_extension        
        assert !flash[:error].blank?
      ensure
        if !tempfile.blank?
          tempfile.close
          tempfile.unlink
        end
      end
    end
    
    test "should succeed with valid spreadsheet" do
      tempfile = Tempfile.new(["dummy_file", ".csv"])
      data = <<-TEXT
      name
      cat
      hello 
      TEXT
      
      begin
        tempfile.write(data)
        tempfile.rewind
        tempfile
        file = Rack::Test::UploadedFile.new(tempfile.path, "text/csv")
        @controller.stubs(:render)
        @controller.stubs(:redirect_to)
        Resque.stubs(:enqueue)
        post :import, object_definition: "Outage", file: file, use_route: :importer_extension        
        assert flash[:error].blank?
      ensure
        if !tempfile.blank?
          tempfile.close
          tempfile.unlink
        end
      end
    end
    
  end
end
