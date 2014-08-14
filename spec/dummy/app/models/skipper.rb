class Skipper < ActiveRecord::Base
  has_drafts :skip => :skip_me
end
