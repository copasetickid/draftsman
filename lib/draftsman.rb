require 'draftsman/config'
require 'draftsman/model'

# Require all frameworks and serializers
Dir[File.join(File.dirname(__FILE__), 'draftsman', 'frameworks', '*.rb')].each { |file| require file }
Dir[File.join(File.dirname(__FILE__), 'draftsman', 'serializers', '*.rb')].each { |file| require file }

# Draftsman's module methods can be called in both models and controllers.
module Draftsman
  # Switches Draftsman on or off.
  def self.enabled=(value)
    Draftsman.config.enabled = value
  end

  # Returns `true` if Draftsman is on, `false` otherwise.
  # Draftsman is enabled by default.
  def self.enabled?
    !!Draftsman.config.enabled
  end

  def self.serialized_attributes?
    ActiveSupport::Deprecation.warn(
      "Draftsman.serialized_attributes? is deprecated without replacement " +
        "and always returns false."
    )
    false
  end

  # Sets whether Draftsman is enabled or disabled for the current request.
  def self.enabled_for_controller=(value)
    draftsman_store[:request_enabled_for_controller] = value
  end

  # Returns `true` if Draftsman is enabled for the request, `false` otherwise.
  #
  # See `Draftsman::Rails::Controller#draftsman_enabled_for_controller`.
  def self.enabled_for_controller?
    !!draftsman_store[:request_enabled_for_controller]
  end

  # Returns whether or not ActiveRecord is configured to require mass assignment whitelisting via `attr_accessible`.
  def self.active_record_protected_attributes?
    @active_record_protected_attributes ||= ActiveRecord::VERSION::STRING.to_f < 4.0 || defined?(ProtectedAttributes)
  end

  # Returns any information from the controller that you want Draftsman to store.
  #
  # See `Draftsman::Controller#info_for_draftsman`.
  def self.controller_info
    draftsman_store[:controller_info]
  end

  # Sets any information from the controller that you want Draftsman to store. By default, this is set automatically by
  # a before filter.
  def self.controller_info=(value)
    draftsman_store[:controller_info] =  value
  end

  # Returns default class name used for drafts.
  def self.draft_class_name
    draftsman_store[:draft_class_name]
  end

  # Sets default class name to use for drafts.
  def self.draft_class_name=(class_name)
    draftsman_store[:draft_class_name] = class_name
  end

  # Set the field which records when a draft was created.
  def self.timestamp_field=(field_name)
    Draftsman.config.timestamp_field = field_name
  end

  # Returns the field which records when a draft was created.
  def self.timestamp_field
    Draftsman.config.timestamp_field
  end

  # Returns serializer to use for `object`, `object_changes`, and `previous_draft` columns.
  def self.serializer
    Draftsman.config.serializer
  end

  # Sets serializer to use for `object`, `object_changes`, and `previous_draft` columns.
  def self.serializer=(value)
    Draftsman.config.serializer = value
  end

  # Returns who is reponsible for any changes that occur.
  def self.whodunnit
    draftsman_store[:whodunnit]
  end

  # Sets who is responsible for any changes that occur.
  # You would normally use this in a migration or on the console,
  # when working with models directly.  In a controller, it is set
  # automatically to the `current_user`.
  def self.whodunnit=(value)
    draftsman_store[:whodunnit] = value
  end

private

  # Thread-safe hash to hold Draftman's data. Initializing with needed default values.
  def self.draftsman_store
    Thread.current[:draft] ||= { :draft_class_name => 'Draftsman::Draft' }
  end

  # Returns Draftman's configuration object.
  def self.config
    @@config ||= Draftsman::Config.instance
  end

  def self.configure
    yield config
  end
end

# Draft model class.
require 'draftsman/draft'

# Inject `Draftsman::Model` into ActiveRecord classes.
ActiveSupport.on_load(:active_record) do
  include Draftsman::Model
end

# Inject `Draftsman::Rails::Controller` into Rails controllers.
if defined?(ActionController)
  ActiveSupport.on_load(:action_controller) do
    include Draftsman::Rails::Controller
  end
end
