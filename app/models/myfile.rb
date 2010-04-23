require 'zip/zipfilesystem'

# Files in the database are represented by Myfile.
# It's called Myfile, because File is a reserved word.
# Files are in (belong to) a folder and are uploaded by (belong to) a User.
class Myfile < ActiveRecord::Base
  #acts_as_ferret :store_class_name => true, :fields => { :text => { :store => :yes }, :filename => { :store => :no } }
  case SEARCHER
  when 'acts_as_ferret'
    acts_as_ferret :fields => { :text => { :store => :yes }, :filename => { :store => :no } }
  when 'acts_as_solr'
    acts_as_solr :fields => [:text, :filename]
  when 'acts_as_tsearch'
    acts_as_tsearch :fields => [:text, :filename]
  end
    
  belongs_to :folder
  belongs_to :user

  has_many :usages, :dependent => :destroy

  has_attached_file :attachment, 
    :processors => [:text_search],
    :path => ":upload_path/:id",
    :default_style => :original,
    :url => "/assets/:id_:basename.:extension"
  
  validates_attachment_presence :attachment
  
  # Search
  def self.find_by_search(*args)
    case SEARCHER
    when 'acts_as_ferret'
      Myfile.find_with_ferret *args
    when 'ats_as_solr'
      Myfile.find_by_solr *args
    when 'acts_as_tsearch'
      Myfile.find_by_tsearch *args
    end
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
