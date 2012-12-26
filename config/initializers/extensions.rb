versions = []
Dir.glob(Rails.root.join("app", "models", "*")).each do |path|
  idx = path.rindex(/\//)
  if idx
    file_portion = path.slice(idx+1, path.length)
    versions << file_portion
  end
end
::AP::ImporterExtension::Importer::Config.instance.latest_version = versions.last