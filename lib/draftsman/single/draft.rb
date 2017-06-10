require 'draftsman/shared_draft_methods.rb'

class Draftsman::Single::Draft < Draftsman::SharedDraftMethods

  belongs_to :item, polymorphic: true

end
