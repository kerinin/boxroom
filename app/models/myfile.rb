require 'zip/zipfilesystem'
require 'mime/types'

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
  
  def dirty_attachment=(data)
    data.content_type = MIME::Types.type_for(data.original_filename).to_s
    self.attachment = data
  end

  private

  # Strip of the path and replace all the non alphanumeric,
  # underscores and periods in the filename with an underscore.
  def normalize_file_name
    # finally, replace all non alphanumeric, underscore or periods with underscore
    attachment_file_name.gsub!(/[^\w\.\-]/, '_') 
  end
end
