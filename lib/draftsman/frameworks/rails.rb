module Draftsman
  module Rails
    module Controller

      def self.included(base)
        base.before_action :set_draftsman_whodunnit, :set_draftsman_controller_info
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

      # Returns any information about the controller or request that you
      # want Draftsman to store alongside any changes that occur.  By
      # default, this returns an empty hash.
      #
      # Override this method in your controller to return a hash of any
      # information you need. The hash's keys must correspond to columns
      # in your `drafts` table, so don't forget to add any new columns
      # you need.
      #
      # For example:
      #
      #     {:ip => request.remote_ip, :user_agent => request.user_agent}
      #
      # The columns `ip` and `user_agent` must exist in your `drafts` # table.
      #
      # Use the `:meta` option to `Draftsman::Model::ClassMethods.has_drafts`
      # to store any extra model-level data you need.
      def info_for_draftsman
        {}
      end

    private

      # Tells Draftsman who is responsible for any changes that occur.
      def set_draftsman_whodunnit
        ::Draftsman.whodunnit = user_for_draftsman
      end

      # Tells Draftsman any information from the controller you want
      # to store alongside any changes that occur.
      def set_draftsman_controller_info
        ::Draftsman.controller_info = info_for_draftsman
      end

    end
  end

  if defined?(::ActionController)
    ::ActiveSupport.on_load(:action_controller) { include Draftsman::Rails::Controller }
  end
end
