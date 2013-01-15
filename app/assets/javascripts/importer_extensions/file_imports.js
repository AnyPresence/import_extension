// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(function () {
  $('#file').live('change', function(){
    $in=$(this); 
    $.post("/api/importer_extension/file_imports/check_file", {file: $in.val()}, function(data) {
      $('#xml').html(data);
    });
  });
});

