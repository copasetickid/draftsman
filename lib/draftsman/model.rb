require 'draftsman/attributes_serialization'
require 'draftsman/single/instance_methods'
require 'draftsman/multiple/instance_methods'

module Draftsman
  module Model

    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      # Declare this in your model to enable the Draftsman API for it. A draft
      # of the model is available in the `draft` association (if one exists).
      #
      # Options:
      #
      # :class_name
      # The name of a custom `Draft` class. This class should inherit from
      # `Draftsman::Single::Draft`. A global default can be set for this using
      # `Draftsman.draft_class_name=` if the default of `Draftsman::Single::Draft` needs
      # to be overridden.
      #
      # :ignore
      # An array of attributes for which an update to a `Draft` will not be
      # stored if they are the only ones changed.
      #
      # :only
      # Inverse of `ignore` - a new `Draft` will be created only for these
      # attributes if supplied. It's recommended that you only specify optional
      # attributes for this (that can be empty).
      #
      # :skip
      # Fields to ignore completely.  As with `ignore`, updates to these fields
      # will not create a new `Draft`. In addition, these fields will not be
      # included in the serialized versions of the object whenever a new `Draft`
      # is created.
      #
      # :meta
      # A hash of extra data to store. You must add a column to the `drafts`
      # table for each key. Values are objects or `procs` (which are called with
      # `self`, i.e. the model with the `has_drafts`). See
      # `Draftsman::Controller.info_for_draftsman` for an example of how to
      # store data from the controller.
      #
      # :draft
      # The name to use for the `draft` association shortcut method. Default is
      # `:draft`.
      #
      # :drafts
      # The name to use for the `drafts` association shortcut method if using multiple drafts. Default is
      # `:drafts`.
      #
      # :published_at
      # The name to use for the method which returns the published timestamp.
      # Default is `published_at`.
      #
      # :trashed_at
      # The name to use for the method which returns the soft delete timestamp.
      # Default is `trashed_at`.
      def has_drafts(options = {})

        class_attribute :multiple
        self.multiple = options[:multiple] || false

        # Lazily include the instance methods so we don't clutter up
        # any more ActiveRecord models than we need to.
        send :include, Draftsman::Multiple::InstanceMethods if self.multiple
        send :include, Draftsman::Single::InstanceMethods if !self.multiple
        send :extend, AttributesSerialization

        # Define before/around/after callbacks on each drafted model
        send :extend, ActiveModel::Callbacks
        # TODO: Remove `draft_creation`, `draft_update`, and `draft_destroy` in
        # v1.0.
        define_model_callbacks :save_draft, :draft_creation, :draft_update, :draft_destruction, :draft_destroy

        class_attribute :draftsman_options
        self.draftsman_options = options.dup

        class_attribute :draft_association_name
        if self.multiple
          self.draft_association_name = options[:drafts] || :drafts
        else
          self.draft_association_name = options[:draft] || :draft
        end

        class_attribute :draft_class_name
        self.draft_class_name = options[:class_name] || Draftsman.multiple_draft_class_name if self.multiple
        self.draft_class_name = options[:class_name] || Draftsman.single_draft_class_name if !self.multiple

        [:ignore, :skip, :only].each do |key|
          draftsman_options[key] = ([draftsman_options[key]].flatten.compact || []).map(&:to_s)
        end

        if self.multiple
          draftsman_options[:ignore] << "#{self.draft_association_name}_count"
        else
          draftsman_options[:ignore] << "#{self.draft_association_name}_id"
        end

        draftsman_options[:meta] ||= {}

        attr_accessor :draftsman_event

        class_attribute :published_at_attribute_name
        self.published_at_attribute_name = options[:published_at] || :published_at

        class_attribute :trashed_at_attribute_name
        self.trashed_at_attribute_name = options[:trashed_at] || :trashed_at

        if self.multiple
          # `has_many :drafts` association
          has_many(self.draft_association_name, class_name: self.draft_class_name, dependent: :destroy, as: :item)
        else
          # `belongs_to :draft` association
          belongs_to(self.draft_association_name, class_name: self.draft_class_name, dependent: :destroy, optional: true)
        end

        # Scopes
        scope :drafted, -> (referenced_table_name = nil) {
          referenced_table_name = referenced_table_name.present? ? referenced_table_name : table_name
          if self.multiple
            where.not(referenced_table_name => { "#{self.draft_association_name}_count" => 0 })
          else
            where.not(referenced_table_name => { "#{self.draft_association_name}_id" => nil })
          end
        }

        scope :published, -> (referenced_table_name = nil) {
          referenced_table_name = referenced_table_name.present? ? referenced_table_name : table_name
          where.not(referenced_table_name => { self.published_at_attribute_name => nil })
        }

        scope :trashed, -> (referenced_table_name = nil) {
          referenced_table_name = referenced_table_name.present? ? referenced_table_name : table_name
          where.not(referenced_table_name => { self.trashed_at_attribute_name => nil })
        }

        scope :live, -> (referenced_table_name = nil) {
          referenced_table_name = referenced_table_name.present? ? referenced_table_name : table_name
          where(referenced_table_name => { self.trashed_at_attribute_name => nil })
        }
      end

      # Returns draft class.
      def draft_class
        @draft_class ||= draft_class_name.constantize
      end

      # Returns whether or not `has_drafts` has been called on this model.
      def draftable?
        method_defined?(:draftsman_options)
      end

      # Returns whether or not a `trashed_at` timestamp is set up on this model.
      def trashable?
        draftable? && method_defined?(self.trashed_at_attribute_name)
      end
    end

  end
end
