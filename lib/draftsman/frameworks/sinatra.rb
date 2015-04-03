require 'active_support/core_ext/object' # provides the `try` method

module Draftsman
  module Sinatra

    # Register this module inside your Sinatra application to gain access to controller-level methods used by Draftsman
    def self.registered(app)
      app.helpers self
      app.before { set_draftsman_whodunnit }
    end

  protected

    # Returns the user who is responsible for any changes that occur.
    # By default this calls `current_user` and returns the result.
    #
    # Override this method in your controller to call a different
    # method, e.g. `current_person`, or anything you like.
    def user_for_draftsman
      return unless defined?(current_user)
      ActiveSupport::VERSION::MAJOR >= 4 ? current_user.try!(:id) : current_user.try(:id)
    rescue NoMethodError
      current_user
    end

  private

    # Tells Draftsman who is responsible for any changes that occur.
    def set_draftsman_whodunnit
      ::Draftsman.whodunnit = user_for_draftsman if ::Draftsman.enabled?
    end

  end

  ::Sinatra.register Draftsman::Sinatra if defined?(::Sinatra)
end
