require 'zip/zipfilesystem'

# Files in the database are represented by Myfile.
# It's called Myfile, because File is a reserved word.
# Files are in (belong to) a folder and are uploaded by (belong to) a User.
class Myfile < ActiveRecord::Base

  # Set up Search library
  send( SEARCH_CONFIG['searcher'], SEARCH_CONFIG['file_args'] ) unless SEARCH_CONFIG['file_args'].nil?
  send( SEARCH_CONFIG['searcher'], &lambda { SEARCH_CONFIG['file_block'].each {|field,args| send( field, args ) } } ) unless SEARCH_CONFIG['file_block'].nil?
  
  belongs_to :folder
  belongs_to :user

  has_many :usages, :dependent => :destroy

  has_attached_file :attachment, 
    :processors => [:text_search],
    :path => ":upload_path/:style/:id",
    :default_style => :original,
    :url => "/assets/:style/:id_:basename.:extension"
  
  validates_attachment_presence :attachment
  
  # Search
  def self.find_by_search(*args)
    # Pass search to search library
    Myfile.send SEARCH_CONFIG['search_signature'], *args
  end

  attr_writer :text # Setter for text
  
  # Getter for text.
  # If text is blank get the text from the index.
  def text
    @text = Myfile.ferret_index[self.document_number][:text] if @text.blank?
  end

  # Strip of the path and replace all the non alphanumeric,
  # underscores and periods in the filename with an underscore.
  def self.base_part_of(file_name)
    # NOTE: File.basename doesn't work right with Windows paths on Unix
    # INCORRECT: just_filename = File.basename(file_name.gsub('\\\\', '/')) 
    # get only the filename, not the whole path
    name = file_name.gsub(/^.*(\\|\/)/, '')

    # finally, replace all non alphanumeric, underscore or periods with underscore
    name.gsub(/[^\w\.\-]/, '_') 
  end

  # The path of the file
  def path
    attachment.url(:original)
  end
end
