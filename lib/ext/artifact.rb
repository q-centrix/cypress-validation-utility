class Artifact
  include Mongoid::Document
  include Mongoid::Timestamps

  MIME_FILE_TYPES = { 'application/zip' => :zip, 'multipart/mixed' => :zip, 'application/x-zip-compressed' => :zip,
                      'application/x-compressed' => :zip, 'multipart/x-zip' => :zip, 'application/xml' => :xml,
                      'text/xml' => :xml }.freeze

  mount_uploader :file, DocumentUploader
  belongs_to :upload, index: true

  field :content_type, type: String
  field :file_size, type: Integer

  before_save :update_asset_attributes

  def archive?
    MIME_FILE_TYPES[content_type] == :zip || File.extname(file.uploaded_filename) == '.zip'
  end

  def file_names
    file_names = []
    if archive?
      Zip::ZipFile.open(file.path) do |zipfile|
        file_names = zipfile.entries.collect(&:name)
      end
    else
      file_names = [file.uploaded_filename]
    end
    file_names
  end

  def file_count
    count = 0
    if archive?
      Zip::ZipFile.open(file.path) do |zipfile|
        count = zipfile.entries.count
      end
    else
      count = 1
    end
    count
  end

  def get_file(name)
    if archive?
      return get_archived_file(name)
    elsif file.uploaded_filename == name
      return file.read
    end
  end

  def get_archived_file(name)
    data = nil
    Zip::ZipFile.open(file.path) do |zipfile|
      data = zipfile.read(name)
    end
    data
  end

  def each_file(&_block)
    if archive?
      Zip::ZipFile.open(file.path) do |zipfile|
        zipfile.glob('*.xml', File::FNM_CASEFOLD | ::File::FNM_PATHNAME | ::File::FNM_DOTMATCH).each do |entry|
          data = zipfile.read(entry.name)
          yield entry.name, data
        end
      end
    else
      yield file.uploaded_filename, file.read
    end
  end

  private

  def update_asset_attributes
    return if !file.present? || !file_changed?
    self.content_type = file.file.content_type
    self.file_size = file.file.size
  end
end
