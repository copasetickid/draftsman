module Sinatra
  module Draftsman

    # Register this module inside your Sinatra application to gain access to controller-level methods used by Draftsman
    def self.registered(app)
      app.helpers Sinatra::Draftsman
      app.before { set_draftsman_whodunnit }
    end

  protected

    # Returns the user who is responsible for any changes that occur.
    # By default this calls `current_user` and returns the result.
    #
    # Override this method in your controller to call a different
    # method, e.g. `current_person`, or anything you like.
    def user_for_draftsman
      current_user if defined?(current_user)
    end

  private

    # Tells Draftsman who is responsible for any changes that occur.
    def set_draftsman_whodunnit
      ::Draftsman.whodunnit = user_for_draftsman
    end

  end

  register Sinatra::Draftsman if defined?(register)
end
