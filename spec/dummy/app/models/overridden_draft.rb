require 'draftsman/single/draft'

class OverriddenDraft < Draftsman::Single::Draft
  def im_overridden
    true
  end
end
