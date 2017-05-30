require 'draftsman/attributes_serialization'

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
      # `Draftsman::Draft`. A global default can be set for this using
      # `Draftsman.draft_class_name=` if the default of `Draftsman::Draft` needs
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
      # :drafts
      # The name to use for the `draft` association shortcut method. Default is
      # `:drafts`.
      #
      # :published_at
      # The name to use for the method which returns the published timestamp.
      # Default is `published_at`.
      #
      # :trashed_at
      # The name to use for the method which returns the soft delete timestamp.
      # Default is `trashed_at`.
      def has_draftsman(options = {})
        # Lazily include the instance methods so we don't clutter up
        # any more ActiveRecord models than we need to.
        send :include, InstanceMethods
        send :extend, AttributesSerialization

        # Define before/around/after callbacks on each drafted model
        send :extend, ActiveModel::Callbacks

        define_model_callbacks :save_draft, :draft_destruction

        class_attribute :draftsman_options
        self.draftsman_options = options.dup

        class_attribute :draft_association_name
        self.draft_association_name = options[:drafts] || :drafts

        class_attribute :draft_class_name
        self.draft_class_name = options[:class_name] || Draftsman.draft_class_name

        [:ignore, :skip, :only].each do |key|
          draftsman_options[key] = ([draftsman_options[key]].flatten.compact || []).map(&:to_s)
        end

        # ignore counter_cache column
        draftsman_options[:ignore] << "#{self.draft_association_name}_count"

        draftsman_options[:meta] ||= {}

        attr_accessor :draftsman_event

        class_attribute :published_at_attribute_name
        self.published_at_attribute_name = options[:published_at] || :published_at

        class_attribute :trashed_at_attribute_name
        self.trashed_at_attribute_name = options[:trashed_at] || :trashed_at

        # `has_many :drafts` association
        has_many(self.draft_association_name, class_name: self.draft_class_name, dependent: :destroy, as: :item)

        # Scopes
        scope :drafted, -> (referenced_table_name = nil) {
          referenced_table_name = referenced_table_name.present? ? referenced_table_name : table_name
          where.not(referenced_table_name => { "#{self.draft_association_name}_count" => [0, nil] })
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

    module InstanceMethods
      # Returns whether or not this item has a draft.
      def has_drafts?
        send(self.class.draft_association_name).any?
      end

      # Trashes object and records a draft for a `destroy` event.
      def draft_destruction
        run_callbacks :draft_destruction do

          transaction do

            data = {
              item: self,
              event: :destroy
            }

            data[:object] = object_attrs_for_draft_record if Draftsman.stash_drafted_changes?
            data[Draftsman.whodunnit_field] = Draftsman.whodunnit
            data = merge_metadata_for_draft(data)

            draft = send(self.class.draft_association_name).new(data)
            draft.save!

            trash!

            # Mock `dependent: :destroy` behavior for all trashable associations
            dependent_associations = self.class.reflect_on_all_associations(:has_one) + self.class.reflect_on_all_associations(:has_many)

            dependent_associations.each do |association|
              if association.klass.draftable? && association.options.has_key?(:dependent) && association.options[:dependent] == :destroy
                dependents = self.send(association.name)
                dependents = [dependents] if (dependents && association.macro == :has_one)

                if dependents
                  dependents.each do |dependent|
                    dependent.draft_destruction unless dependent.has_drafts && dependent.send(dependent.class.draft_association_name).destroy?
                  end
                end
              end
            end
          end
        end
      end

      # Returns serialized object representing this drafted item.
      def object_attrs_for_draft_record(object = nil)
        object ||= self

        attrs = object.attributes.except(*self.class.draftsman_options[:skip]).tap do |attributes|
          self.class.serialize_attributes_for_draftsman(attributes)
        end

        if self.class.draft_class.object_col_is_json?
          attrs
        else
          Draftsman.serializer.dump(attrs)
        end
      end

      # Returns whether or not this item has been published at any point in its lifecycle.
      def published?
        self.published_at.present?
      end

      # Creates or updates draft depending on state of this item and if it has
      # any drafts.
      #
      # -  If a completely new record, persists this item to the database and
      #    records a `create` draft.
      # -  If an existing record with an existing `create` draft, updates the
      #    record and the existing `create` draft.
      # -  If an existing record with no existing draft, records changes in an
      #    `update` draft.
      # -  If an existing record with an existing draft (`create` or `update`),
      #    updated back to its original undrafted state, removes associated
      #    `draft record`.
      #
      # Returns `true` or `false` depending on if the object passed validation
      # and the save was successful.
      def save_draft
        run_callbacks :save_draft do
          if self.new_record?
            _draft_creation
          else
            _draft_update
          end
        end
      end

      # Returns whether or not this item has been trashed
      def trashed?
        send(self.class.trashed_at_attribute_name).present?
      end

      private

      # Creates object and records a draft for the object's creation. Returns
      # `true` or `false` depending on whether or not the objects passed
      # validation and the save was successful.
      def _draft_creation
        transaction do
          # We want to save the draft after create
          return false unless self.save
          # Build data to store in draft record.
          data = {
            item: self,
            event: :create,
          }

          data[:object] = object_attrs_for_draft_record if Draftsman.stash_drafted_changes?
          data[Draftsman.whodunnit_field] = Draftsman.whodunnit
          data[:object_changes] = serialized_draft_changeset(changes_for_draftsman(:create)) if track_object_changes_for_draft?
          data = merge_metadata_for_draft(data)

          draft = send(self.class.draft_association_name).new(data)

          if !draft.save
            raise ActiveRecord::Rollback and return false
          end
        end

        return true
      end

      # CHANGE: every update is conisdered a new draft,
      # so no need to update or destroy existing drafts

      # Updates object and records a draft for an `update` event. If the draft
      # is being updated to the object's original state, the draft is destroyed.
      # Returns `true` or `false` depending on if the object passed validation
      # and the save was successful.
      def _draft_update
        transaction do

          # Run validations.
          return false unless self.valid?

          the_changes = changes_for_draftsman(:update)
          save_only_columns_for_draft if Draftsman.stash_drafted_changes?

          # Save an update draft if record is changed notably.
          if !the_changes.empty?
            data = { item: self, event: :update }
            data[Draftsman.whodunnit_field] = Draftsman.whodunnit
            data[:object] = object_attrs_for_draft_record if Draftsman.stash_drafted_changes?
            data[:object_changes] = serialized_draft_changeset(the_changes) if track_object_changes_for_draft?
            data = merge_metadata_for_draft(data)

            # create an update draft.
            draft = send(self.class.draft_association_name).new(data)

            if draft.save
              if Draftsman.stash_drafted_changes?
                update_skipped_attributes
              else
                self.save
              end
            else
              raise ActiveRecord::Rollback and return false
            end
            # Otherwise, just save the record.
          else
            self.save
          end
        end
      rescue Exception => e
        false
      end

      # Returns hash of attributes that have changed for the object, similar to
      # how ActiveRecord's `changes` works.
      def changes_for_draftsman(event)
        the_changes = {}
        ignore = self.class.draftsman_options[:ignore]
        skip   = self.class.draftsman_options[:skip]
        only   = self.class.draftsman_options[:only]
        draftable_attrs = self.attributes.keys - ignore - skip
        draftable_attrs = draftable_attrs & only if only.present?

        # If there's already an update draft, get its changes and reconcile them
        # manually.
        if event == :update
          # Collect all attributes' previous and new values.
          draftable_attrs.each do |attr|
            the_changes[attr] = [self.send("#{attr}_was"), send(attr)]
          end
          # If there is no draft or it's for a create, then all draftable
          # attributes are the changes.
        else
          draftable_attrs.each { |attr| the_changes[attr] = [nil, send(attr)] }
        end

        # Purge attributes that haven't changed.
        the_changes.delete_if { |key, value| value.first == value.last }
      end

      # Merges model-level metadata from `meta` and `controller_info` into draft object.
      def merge_metadata_for_draft(data)
        # First, we merge the model-level metadata in `meta`.
        draftsman_options[:meta].each do |attribute, value|
          data[attribute] =
          if value.respond_to?(:call)
            value.call(self)
          elsif value.is_a?(Symbol) && respond_to?(value)
            # if it is an attribute that is changing, be sure to grab the current version
            if has_attribute?(value) && send("#{value}_changed?".to_sym)
              send("#{value}_was".to_sym)
            else
              send(value)
            end
          else
            value
          end
        end

        # Second, we merge any extra data from the controller (if available).
        data.merge(Draftsman.controller_info || {})
      end

      # Save columns outside of the `only` option directly to master table
      def save_only_columns_for_draft
        if self.class.draftsman_options[:only].any?
          only_changes = {}
          only_changed_attributes = self.attributes.keys - self.class.draftsman_options[:only]

          only_changed_attributes.each do |key|
            only_changes[key] = send(key) if changed.include?(key)
          end

          self.update_columns(only_changes) if only_changes.any?
        end
      end

      # Returns changeset data in format appropriate for `object_changes`
      # column.
      def serialized_draft_changeset(my_changes)
        self.class.draft_class.object_changes_col_is_json? ? my_changes : Draftsman.serializer.dump(my_changes)
      end

      # Returns whether or not the draft class includes an `object_changes` attribute.
      def track_object_changes_for_draft?
        self.class.draft_class.column_names.include?('object_changes')
      end

      # Sets `trashed_at` attribute to now and saves to the database immediately.
      def trash!
        self.update_column(self.class.trashed_at_attribute_name, Time.now)
      end

      # Updates skipped attributes' values on this model.
      def update_skipped_attributes
        # Skip over this if nothing's being skipped.
        return true unless draftsman_options[:skip].present?

        keys = self.attributes.keys.select { |key| draftsman_options[:skip].include?(key) }
        attrs = {}
        keys.each { |key| attrs[key] = self.send(key) }

        self.reload
        self.update(attrs)
      end
    end
  end
end
