class OnlyChild < ActiveRecord::Base
  has_drafts
  belongs_to :parent
end
