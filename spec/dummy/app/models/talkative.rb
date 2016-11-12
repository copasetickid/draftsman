class Talkative < ActiveRecord::Base
  has_drafts

  # draft_creation callbacks
  before_save_draft :do_this_before_save
  around_save_draft :do_this_around_save
  after_save_draft :do_this_after_save

  # draft_destruction callbacks
  before_draft_destruction :do_this_before_destruction
  around_draft_destruction :do_this_around_destruction
  after_draft_destruction :do_this_after_destruction

private

  def do_this_before_save
    self.before_comment = 'I changed before save'
  end

  def do_this_around_save
    self.around_early_comment = 'I changed around save (before yield)'
    yield
    self.around_late_comment = 'I changed around save (after yield)'
  end

  def do_this_after_save
    self.after_comment = 'I changed after save'
  end


  def do_this_before_destruction
    self.before_comment = 'I changed before destroy'
  end

  def do_this_around_destruction
    self.around_early_comment = 'I changed around destroy (before yield)'
    yield
    self.around_late_comment = 'I changed around destroy (after yield)'
  end

  def do_this_after_destruction
    self.after_comment = 'I changed after destroy'
  end
end
