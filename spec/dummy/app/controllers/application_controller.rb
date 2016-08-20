class ApplicationController < ActionController::Base
  protect_from_forgery
  before_action :set_draftsman_whodunnit

  def create
    Trashable.new(name: 'Bob').draft_creation
    head :no_content
  end

  def update
    trashable = Trashable.last
    trashable.name = 'Sam'
    trashable.draft_update
    head :no_content
  end

  def destroy
    Trashable.last.draft_destruction
    head :no_content
  end

  private

  def draftsman_enabled_for_controller
    request.user_agent != 'Disable User-Agent'
  end
end
