versions = []
Dir.glob(Rails.root.join("app", "models", "*")).each do |path|
  idx = path.rindex(/\//)
  if idx
    file_portion = path.slice(idx+1, path.length)
    versions << $1.to_i if file_portion.match(/v(\d+)/)
  end
end

::AP::ImporterExtension::Importer::Config.instance.latest_version = "V#{versions.sort.last}"