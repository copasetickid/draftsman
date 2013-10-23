class SetUpTestTables < ActiveRecord::Migration
  def self.up
    create_table :drafts, :force => true do |t|
      t.string  :item_type
      t.integer :item_id
      t.string  :event, :null => false
      t.string  :whodunnit
      t.text    :object
      t.text    :object_changes
      t.text    :previous_draft
      t.timestamps

      # Metadata column
      t.integer :answer

      # Controller info column
      t.string :ip
      t.string :user_agent
    end

    create_table :vanillas, :force => true do |t|
      t.string     :name
      t.references :draft
      t.datetime   :published_at
      t.timestamps
    end

    create_table :trashables, :force => true do |t|
      t.string     :name
      t.string     :title, :null => true
      t.references :draft
      t.datetime   :published_at
      t.datetime   :trashed_at
      t.timestamps
    end

    create_table :draft_as_sketches, :force => true do |t|
      t.string     :name
      t.references :sketch
      t.datetime   :published_at
      t.timestamps
    end

    create_table :whitelisters, :force => true do |t|
      t.string     :name
      t.string     :ignored
      t.references :draft
      t.datetime   :published_at
      t.timestamps
    end

    create_table :parents, :force => true do |t|
      t.string     :name
      t.references :draft
      t.datetime   :trashed_at
      t.datetime   :published_at
      t.timestamps
    end

    create_table :children, :force => true do |t|
      t.string     :name
      t.references :parent
      t.references :draft
      t.datetime   :trashed_at
      t.datetime   :published_at
      t.timestamps
    end

    create_table :bastards, :force => true do |t|
      t.string     :name
      t.references :parent
      t.timestamps
    end
  end

  def self.down
    drop_table :drafts
    drop_table :vanillas
    drop_table :trashables
    drop_table :draft_as_sketches
    drop_table :whitelisters
    drop_table :parents
    drop_table :children
    drop_table :bastards
  end
end
