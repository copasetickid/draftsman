class CreateEnumables < ActiveRecord::Migration
  def change
    create_table :enumables do |t|
      t.integer :status, :null => false
      t.references :draft
      t.timestamp :published_at
    end
  end
end
