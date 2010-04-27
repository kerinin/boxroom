# A folder is a place where files can be stored.
# Folders can also have sub-folders.
# Via groups it is determined which actions the logged-in User can perform.
class Folder < ActiveRecord::Base

  # Set up Search library
  case  CONFIG[:searcher]
  when :ferret
    acts_as_ferret :store_class_name => true, :fields => { :name => { :store => :no } }
  when :texticle
    index { name }
  end
  
  acts_as_tree :order => 'name'

  belongs_to :user
  has_many :myfiles, :dependent => :destroy
  has_many :group_permissions, :dependent => :destroy

  validates_uniqueness_of :name, :scope => 'parent_id'
  validates_presence_of :name

  attr_accessible :name

  # Search
  def self.find_by_search(*args)
    # Pass search to search library
    case CONFIG[:searcher]
    when :ferret
      Folder.find_with_ferret *args
    when :texticle
      Folder.search *args
    else
      []
    end
  end
  
  # List subfolders
  # for the given user in the given order.
  def list_subfolders(logged_in_user, order)
    folders = []
    if logged_in_user.can_read(self.id)
      self.children.find(:all, :order => order).each do |sub_folder|
        folders << sub_folder if logged_in_user.can_read(sub_folder.id)
      end
    end

    # return the folders:
    return folders
  end

  # List the files
  # for the given user in the given order.
  def list_files(logged_in_user, order)
    files = []
    if logged_in_user.can_read(self.id)
      files = self.myfiles.find(:all, :order => order)
    end

    # return the files:
    return files
  end

  # Returns whether or not the root folder exists
  def self.root_folder_exists?
    folder = Folder.find_by_is_root(true)
    return (not folder.blank?)
  end

  # Create the Root folder
  def self.create_root_folder
    if User.admin_exists? #and  Folder.root_folder_exists?
      folder = self.new
      folder.name = 'Root folder'
      folder.date_modified = Time.now
      folder.is_root = true

      # This folder is created by the admin
      if user = User.find_by_is_the_administrator(true)
        folder.user = user
      end

      folder.save # this hopefully returns true
    end
  end
  
  # Copy the GroupPermissions of the parent folder to the given folder
  def copy_permissions_from(folder)
    f_id = folder.instance_of?(Folder) ? folder.id : folder
      
    # get the 'parent' GroupPermissions
    GroupPermission.find_all_by_folder_id(f_id).each do |parent_group_permissions|
      # create the new GroupPermissions
      group_permissions = GroupPermission.new
      group_permissions.folder = self
      group_permissions.group = parent_group_permissions.group
      group_permissions.can_create = parent_group_permissions.can_create
      group_permissions.can_read = parent_group_permissions.can_read
      group_permissions.can_update = parent_group_permissions.can_update
      group_permissions.can_delete = parent_group_permissions.can_delete
      group_permissions.save
    end
  end
end
