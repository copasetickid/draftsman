require 'draftsman/draft'

class OverriddenDraft < Draftsman::Draft
  def im_overridden
    true
  end
end
