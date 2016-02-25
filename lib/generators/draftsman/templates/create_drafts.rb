class CreateDrafts < ActiveRecord::Migration
  def change
    create_table :drafts do |t|
      t.string  :item_type, :null => false
      t.integer :item_id,   :null => false
      t.string  :event,     :null => false
      t.string  :whodunnit#  :null => false
      t.text    :object
      t.text    :previous_draft
      t.timestamps          :null => false
    end

    change_table :drafts do |t|
      t.index :item_type
      t.index :item_id
      t.index :event
      t.index :whodunnit
      t.index :created_at
      t.index :updated_at
    end
  end
end
