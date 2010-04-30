class AddStyleToUsage < ActiveRecord::Migration
  def self.up
    add_column :usages, :style, :string, :default => 'original'
  end

  def self.down
    remove_column :usages, :style
  end
end
