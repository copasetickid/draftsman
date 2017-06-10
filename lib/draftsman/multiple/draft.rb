require 'draftsman/shared_draft_methods.rb'


class Draftsman::Multiple::Draft < Draftsman::SharedDraftMethods

  belongs_to :item, polymorphic: true, counter_cache: true

end
