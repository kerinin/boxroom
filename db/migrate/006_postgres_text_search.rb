class PostgresTextSearch < ActiveRecord::Migration
  def self.up
    add_column :myfiles, :text, :text
  
    execute "CREATE TEXT SEARCH CONFIGURATION public.default ( COPY = pg_catalog.english )"
  end

  def self.down
    remove_column :myfiles, :text
  end
end
