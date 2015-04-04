class AddTalkativesTableToTests < ActiveRecord::Migration
  def self.up
    create_table :talkatives, :force => true do |t|
      t.string     :before_comment
      t.string     :around_early_comment
      t.string     :around_late_comment
      t.string     :after_comment
      t.references :draft
      t.datetime   :trashed_at
      t.datetime   :published_at
      t.timestamps
    end
  end

  def self.down
    drop_table :talkatives
  end
end
