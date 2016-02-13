class Talkative < ActiveRecord::Base
  has_drafts

  # draft_creation callbacks
  before_draft_creation :do_this_before_draft_creation
  around_draft_creation :do_this_around_draft_creation
  after_draft_creation :do_this_after_draft_creation

  # draft_update callbacks
  before_draft_update :do_this_before_draft_update
  around_draft_update :do_this_around_draft_update
  after_draft_update :do_this_after_draft_update

  # # draft_destroy callbacks
  before_draft_destroy :do_this_before_draft_destroy
  around_draft_destroy :do_this_around_draft_destroy
  after_draft_destroy :do_this_after_draft_destroy

private

  def do_this_before_draft_creation
    self.before_comment = "I changed before creation"
  end

  def do_this_around_draft_creation
    self.around_early_comment = "I changed around creation (before yield)"
    yield
    self.around_late_comment = "I changed around creation (after yield)"
  end

  def do_this_after_draft_creation
    self.after_comment = "I changed after creation"
  end



  def do_this_before_draft_update
    self.before_comment = "I changed before update"
  end

  def do_this_around_draft_update
    self.around_early_comment = "I changed around update (before yield)"
    yield
    self.around_late_comment = "I changed around update (after yield)"
  end

  def do_this_after_draft_update
    self.after_comment = "I changed after update"
  end



  def do_this_before_draft_destroy
    self.before_comment = "I changed before destroy"
  end

  def do_this_around_draft_destroy
    self.around_early_comment = "I changed around destroy (before yield)"
    yield
    self.around_late_comment = "I changed around destroy (after yield)"
  end

  def do_this_after_draft_destroy
    self.after_comment = "I changed after destroy"
  end
end
