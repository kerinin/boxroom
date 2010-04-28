require 'zip/zipfilesystem'

# Files in the database are represented by Myfile.
# It's called Myfile, because File is a reserved word.
# Files are in (belong to) a folder and are uploaded by (belong to) a User.
class Myfile < ActiveRecord::Base
  belongs_to :folder
  belongs_to :user

  has_many :usages, :dependent => :destroy
  
  before_save :normalize_file_name

  has_attached_file :attachment, CONFIG[:paperclip]
  
  validates_attachment_presence :attachment
  validates_uniqueness_of :attachment_file_name, :scope => 'folder_id'

  # Set up Search library
  case CONFIG[:searcher]
  when :ferret
    acts_as_ferret :store_class_name => true, :fields => { :text => { :store => :yes }, :attachment_file_name => { :store => :no } }

    attr_accessor :text # Setter for text 
       
    # Getter for text.
    # If text is blank get the text from the index.
    def text
      @text || Myfile.aaf_index.ferret_index[self.document_number][:text]
    end
  when :texticle
    ## For full text search the following line should be uncommented
    #index { text; attachment_file_name }
    index { attachment_file_name }
  end
  
  # Search
  def self.find_by_search(*args)
    # Pass search to search library
    case CONFIG[:searcher]
    when :ferret
      Myfile.find_with_ferret *args
    when :texticle
      Myfile.search *args
    else
      []
    end
  end
  
  # Index
  def index_file_contents text_in_file
    unless text_in_file.blank?  
      case CONFIG[:searcher]
      when :ferret
        self.text = text_in_file.strip   # assign text_in_file to self.text to get it indexed
        self.indexed = true
      when :texticle
        self.text = text_in_file.strip
      end
    end
  end

  # The path of the file
  def path
    attachment.path
  end
  
  # Returns true if myfile is an archive capable of being expanded
  def is_archive?
    [ 'application/zip', 
    'application/x-zip', 
    'multipart/x-zip'
    ].include? attachment_content_type
  end
  
  # Returns true if the file is an archive and can be expanded
  # into the parent folder without over-writing any existing files
  def archive_root_elements_exist?
    raise "This file is not an archive" unless is_archive?
    
    root_dir_names = folder.children.map(&:name)
    root_file_names = folder.myfiles.map(&:attachment_file_name)
    puts root_dir_names
    
    Zip::ZipFile.open(attachment.path) do |zipfile|
      # Check for conflicts
      zipfile.dir.entries('/').each do |entry|       
        return true if ( zipfile.file.file?( entry ) && root_file_names.include?(entry) )
        return true if ( zipfile.file.directory?( entry ) && root_dir_names.include?(entry) )
      end
    end
    false
  end

  # Expands the contents of an archive into folder
  def expand_archive zipfile = nil, folder = nil, dirname = ''
    if zipfile.nil?
      zipfile = Zip::ZipFile.open(attachment.path)
    end
    if folder.nil?
      folder = self.folder
    end
    
    # Add files
    zipfile.dir.entries( dirname ).each do |basename|
      path = ( dirname == '' ? basename : File.join(dirname,basename))
      
      if zipfile.file.directory? path
        # create folder
        newfolder = Folder.new(:name => basename)
        newfolder.parent_id = folder.id
        newfolder.date_modified = Time.now
        newfolder.user = @logged_in_user
        
        if newfolder.save!
          # copy groups rights on parent folder to new folder
          newfolder.copy_permissions_from folder
          
          # recursion
          expand_archive zipfile, newfolder, path
        end
      else
        # create file
        tmp = File.join( Dir.tmpdir, 'boxroom', basename )
        FileUtils.mkdir_p( File.dirname tmp )
        zipfile.extract path, tmp
        
        file = Myfile.new :attachment => File.new(tmp)
        file.folder_id = folder.id
        file.user = @logged_in_user
        file.save!
            
        File.delete tmp
      end
    end
  end
     
  def thumbnail_url(style = :original)
    # NOTE:  this is returning styles for thumbnails but not icons :(
    return attachment.url(style) if has_thumbnail?
    
    url_full = image_path "mime-types/#{self.attachment_content_type.sub('/','-')}.png"
    return url_full if File.exists?( url_full )
    
    url_general = image_path "mime-types/#{self.attachment_content_type.split('/')[0]}.png"
    return url_general if File.exists?( url_general )
    
    return image_path "mime-types/empty.png"    
  end
  
  def has_thumbnail?
    # NOTE: Make sure imagemagick handles all this...
    [ 'image/jpeg',
    'image/gif',
    'image/png',
    'image/tiff',
    'image/psd',
    'image/x-ms-bmp',
    'application/pdf',
    'application/x-pdf',
    'application/postscript',
    'application/illustrator'
    ].include? self.attachment_content_type
  end
       
  private

  # Strip of the path and replace all the non alphanumeric,
  # underscores and periods in the filename with an underscore.
  def normalize_file_name
    # finally, replace all non alphanumeric, underscore or periods with underscore
    attachment_file_name.gsub!(/[^\w\.\-]/, '_') 
  end
end
