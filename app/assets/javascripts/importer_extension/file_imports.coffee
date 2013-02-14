class ImportForm
  @importTypeFieldName: 'selected_import_type'
  @fileUploadSelector: '.file-upload'
  @setImportType: (typeName) ->
    $("[name=\"#{@importTypeFieldName}\"]").val typeName
  @showFileUploadField: -> $("#{@fileUploadSelector}").show()
  @hideFileUploadField: -> $("#{@fileUploadSelector}").hide()
  @onTypeTabChange: (e) ->
    tab = $ e.target
    importType = tab.attr('data-type')
    showFileUpload = tab.attr('data-file_upload')?
    @setImportType importType
    @hideFileUploadField()
    @showFileUploadField() if showFileUpload


$ ->
  $('.import-type-nav').bind('show', $.proxy(ImportForm.onTypeTabChange, ImportForm))
  $('.import-type-nav a:first').trigger('show')
