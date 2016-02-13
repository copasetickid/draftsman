class ApplicationController < ActionController::Base
  protect_from_forgery

  def create
    Trashable.new(:name => 'Bob').draft_creation
    render nothing: true
  end

  def update
    trashable = Trashable.last
    trashable.name = 'Sam'
    trashable.draft_update
    render nothing: true
  end

  def destroy
    Trashable.last.draft_destruction
    render nothing: true
  end
end
