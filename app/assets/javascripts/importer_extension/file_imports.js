// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(function() {
    $("[rel=tooltip]").tooltip();  
    
    var val = $("input:radio[name=selected_import_type]").val();
    selectedImportedType(val);
    
    $("input:radio[name=selected_import_type]").live('change', function() { 
      var val = $("input:radio[name=selected_import_type]:checked").val();
      selectedImportedType(val);
    });

  } 
);

function selectedImportedType(selection) {
  var divHash = {};
  divHash["Local Spreadsheet"] = "local_spreadsheet";
  divHash["Google Spreadsheet"] = "google_spreadsheet";
  divHash["XML"] = "xml"
  for (var k in divHash) {
    $("div#" + divHash[k]).hide();
  }
  // Hide input file
  $("div#input_file").hide();
  
  $("div#" + divHash[selection]).show();
  if (selection == "Local Spreadsheet" || selection == "XML")
    $("div#input_file").show();
}