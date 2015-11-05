class AddOnlyChildren < ActiveRecord::Migration
  def up
    create_table :only_children, :force => true do |t|
      t.string     :name
      t.references :parent
      t.references :draft, :foreign_key => true
      t.datetime   :trashed_at
      t.datetime   :published_at
      t.timestamps
    end
  end

  def down
    drop_table :only_children
  end
end
