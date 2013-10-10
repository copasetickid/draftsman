class AddObjectChangesColumnToDrafts < ActiveRecord::Migration
  def self.up
    add_column :drafts, :object_changes, :text
  end

  def self.down
    remove_column :drafts, :object_changes
  end
end
