class Whitelister < ActiveRecord::Base
  has_drafts only: [:name]
end
