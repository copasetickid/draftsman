module Draftsman
  module Rails
    module Controller
      def self.included(base)
        before = [
          :set_draftsman_enabled_for_controller,
          :set_draftsman_controller_info
        ]
        after = [
          :warn_about_not_setting_whodunnit
        ]
        if base.respond_to? :before_action
          # Rails 4+
          before.map { |sym| base.before_action sym }
          after.map  { |sym| base.after_action  sym }
        else
          # Rails 3.
          before.map { |sym| base.before_filter sym }
          after.map  { |sym| base.after_filter  sym }
        end
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

      # Returns `true` (default) or `false` depending on whether Draftsman
      # should be active for the current request.
      #
      # Override this method in your controller to specify when Draftsman
      # should be off.
      def draftsman_enabled_for_controller
        ::Draftsman.enabled?
      end

    private

      # Tells Draftsman whether drafts should be saved in the current request.
      def set_draftsman_enabled_for_controller
        ::Draftsman.enabled_for_controller = draftsman_enabled_for_controller
      end

      # Tells Draftsman who is responsible for any changes that occur.
      def set_draftsman_whodunnit
        @set_draftsman_whodunnit_called = true
        ::Draftsman.whodunnit = user_for_draftsman if ::Draftsman.enabled_for_controller?
      end

      # Tells Draftsman any information from the controller you want to store
      # alongside any changes that occur.
      def set_draftsman_controller_info
        ::Draftsman.controller_info = info_for_draftsman
      end

      def warn_about_not_setting_whodunnit
        enabled = ::Draftsman.enabled_for_controller?
        user_present = user_for_draftsman.present?
        whodunnit_blank = ::Draftsman.whodunnit.blank?
        if enabled && user_present && whodunnit_blank && !@set_draftsman_whodunnit_called
          ::Kernel.warn <<-EOS.strip_heredoc
            user_for_draftsman is present, but whodunnit has not been set.
            Draftsman no longer adds the set_draftsman_whodunnit callback for
            you. To continue recording whodunnit, please add this before_action
            callback to your ApplicationController . For more information,
            please see https://git.io/vrTsk
          EOS
        end
      end
    end
  end

  if defined?(::ActionController)
    ::ActiveSupport.on_load(:action_controller) do
      include ::Draftsman::Rails::Controller
    end
  end
end
