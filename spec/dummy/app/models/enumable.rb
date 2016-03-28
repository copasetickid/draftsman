class Enumable < ActiveRecord::Base
  has_drafts
  enum status: { active: 0, archived: 1 }
end
