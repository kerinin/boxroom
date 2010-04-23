class ChangeMyfileToPaperclip < ActiveRecord::Migration
  def self.up
    rename_column :myfiles, :filename, :attachment_file_name
    rename_column :myfiles, :filesize, :attachment_file_size
    rename_column :myfiles, :date_modified, :attachment_updated_at
    
    add_column :myfiles, :attachment_content_type, :string

    remove_index :myfiles, :date_modified
    remove_index :myfiles, :filename
    remove_index :myfiles, :filesize    

    add_index "myfiles", :attachment_updated_at, :name => "index_myfiles_on_date_attachment_updated_at"
    add_index "myfiles", :attachment_file_name, :name => "index_myfiles_on_attachment_file_name"
    add_index "myfiles", :attachment_file_size, :name => "index_myfiles_on_attachment_file_size"
  end

  def self.down
    rename_column :myfiles, :attachment_file_name, :filename
    rename_column :myfiles, :attachment_file_size, :filesize
    rename_column :myfiles, :attachment_updated_at, :date_modified
    
    remove_column :myfiles, :attachment_content_type

    remove_index "myfiles", :attachment_updated_at
    remove_index "myfiles", :attachment_file_name
    remove_index "myfiles", :attachment_file_size
    
    add_index "myfiles", ["date_modified"], :name => "index_myfiles_on_date_modified"
    add_index "myfiles", ["filename"], :name => "index_myfiles_on_filename"
    add_index "myfiles", ["filesize"], :name => "index_myfiles_on_filesize"
  end
end

