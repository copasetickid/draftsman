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
      # :draft
      # The name to use for the `draft` association shortcut method. Default is
      # `:draft`.
      #
      # :published_at
      # The name to use for the method which returns the published timestamp.
      # Default is `published_at`.
      #
      # :trashed_at
      # The name to use for the method which returns the soft delete timestamp.
      # Default is `trashed_at`.
      def has_drafts(options = {})
        # Lazily include the instance methods so we don't clutter up
        # any more ActiveRecord models than we need to.
        send :include, InstanceMethods
        send :extend, AttributesSerialization

        # Define before/around/after callbacks on each drafted model
        send :extend, ActiveModel::Callbacks
        # TODO: Remove `draft_creation`, `draft_update`, and `draft_destroy` in
        # v1.0.
        define_model_callbacks :save_draft, :draft_creation, :draft_update, :draft_destruction, :draft_destroy

        class_attribute :draftsman_options
        self.draftsman_options = options.dup

        class_attribute :draft_association_name
        self.draft_association_name = options[:draft] || :draft

        class_attribute :draft_class_name
        self.draft_class_name = options[:class_name] || Draftsman.draft_class_name

        [:ignore, :skip, :only].each do |key|
          draftsman_options[key] = ([draftsman_options[key]].flatten.compact || []).map(&:to_s)
        end

        draftsman_options[:ignore] << "#{self.draft_association_name}_id"

        draftsman_options[:meta] ||= {}

        attr_accessor :draftsman_event

        class_attribute :published_at_attribute_name
        self.published_at_attribute_name = options[:published_at] || :published_at

        class_attribute :trashed_at_attribute_name
        self.trashed_at_attribute_name = options[:trashed_at] || :trashed_at

        # `belongs_to :draft` association
        belongs_to(self.draft_association_name, class_name: self.draft_class_name, dependent: :destroy, optional: true)

        # Scopes
        scope :drafted, -> (referenced_table_name = nil) {
          referenced_table_name = referenced_table_name.present? ? referenced_table_name : table_name
          where.not(referenced_table_name => { "#{self.draft_association_name}_id" => nil })
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
      def draft?
        send(self.class.draft_association_name).present?
      end

      # DEPRECATED: Use `#draft_save` instead.
      def draft_creation
        ActiveSupport::Deprecation.warn('`#draft_creation` is deprecated and will be removed from Draftsman 1.0. Use `#save_draft` instead.')
        _draft_creation
      end

      # DEPRECATED: Use `#draft_destruction` instead.
      def draft_destroy
        ActiveSupport::Deprecation.warn('`#draft_destroy` is deprecated and will be removed from Draftsman 1.0. Use `draft_destruction` instead.')

        run_callbacks :draft_destroy do
          _draft_destruction
        end
      end

      # Trashes object and records a draft for a `destroy` event.
      def draft_destruction
        run_callbacks :draft_destruction do
          _draft_destruction
        end
      end

      # DEPRECATED: Use `#draft_save` instead.
      def draft_update
        ActiveSupport::Deprecation.warn('`#draft_update` is deprecated and will be removed from Draftsman 1.0. Use `#save_draft` instead.')
        _draft_update
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
          # TODO: Remove callback wrapper in v1.0.
          run_callbacks :draft_creation do
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
            send("build_#{self.class.draft_association_name}", data)

            if send(self.class.draft_association_name).save
              fk = "#{self.class.draft_association_name}_id"
              id = send(self.class.draft_association_name).id
              self.update_column(fk, id)
            else
              raise ActiveRecord::Rollback and return false
            end
          end
        end

        return true
      end

      # This is only abstracted away at this moment because of the
      # `draft_destroy` deprecation. Move all of this logic back into
      # `draft_destruction` after `draft_destroy is removed.`
      def _draft_destruction
        transaction do
          data = {
            item: self,
            event: :destroy
          }
          data[:object] = object_attrs_for_draft_record if Draftsman.stash_drafted_changes?
          data[Draftsman.whodunnit_field] = Draftsman.whodunnit

          # Stash previous draft in case it needs to be reverted later
          if self.draft?
            attrs = send(self.class.draft_association_name).attributes

            data[:previous_draft] =
              if self.class.draft_class.previous_draft_col_is_json?
                attrs
              else
                Draftsman.serializer.dump(attrs)
              end
          end

          data = merge_metadata_for_draft(data)

          if send(self.class.draft_association_name).present?
            send(self.class.draft_association_name).update!(data)
          else
            send("build_#{self.class.draft_association_name}", data)
            send(self.class.draft_association_name).save!
            send("#{self.class.draft_association_name}_id=", send(self.class.draft_association_name).id)
            self.update_column("#{self.class.draft_association_name}_id", send(self.class.draft_association_name).id)
          end

          trash!

          # Mock `dependent: :destroy` behavior for all trashable associations
          dependent_associations = self.class.reflect_on_all_associations(:has_one) + self.class.reflect_on_all_associations(:has_many)

          dependent_associations.each do |association|
            if association.klass.draftable? && association.options.has_key?(:dependent) && association.options[:dependent] == :destroy
              dependents = self.send(association.name)
              dependents = [dependents] if (dependents && association.macro == :has_one)

              if dependents
                dependents.each do |dependent|
                  dependent.draft_destruction unless dependent.draft? && dependent.send(dependent.class.draft_association_name).destroy?
                end
              end
            end
          end
        end
      end

      # Updates object and records a draft for an `update` event. If the draft
      # is being updated to the object's original state, the draft is destroyed.
      # Returns `true` or `false` depending on if the object passed validation
      # and the save was successful.
      def _draft_update
        # TODO: Remove callback wrapper in v1.0.
        transaction do
          run_callbacks :draft_update do
            # Run validations.
            return false unless self.valid?

            # If updating a create draft, also update this item.
            if self.draft? && send(self.class.draft_association_name).create?
              the_changes = changes_for_draftsman(:create)
              data = { item: self }
              data[Draftsman.whodunnit_field] = Draftsman.whodunnit
              data[:object] = object_attrs_for_draft_record if Draftsman.stash_drafted_changes?
              data[:object_changes] = serialized_draft_changeset(the_changes) if track_object_changes_for_draft?

              data = merge_metadata_for_draft(data)
              send(self.class.draft_association_name).update(data)
              self.save
            else
              the_changes = changes_for_draftsman(:update)
              save_only_columns_for_draft if Draftsman.stash_drafted_changes?

              # Destroy the draft if this record has changed back to the original
              # record.
              if self.draft? && the_changes.empty?
                nilified_draft = send(self.class.draft_association_name)
                send("#{self.class.draft_association_name}_id=", nil)
                self.save
                nilified_draft.destroy
              # Save an update draft if record is changed notably.
              elsif !the_changes.empty?
                data = { item: self, event: :update }
                data[Draftsman.whodunnit_field] = Draftsman.whodunnit
                data[:object] = object_attrs_for_draft_record if Draftsman.stash_drafted_changes?
                data[:object_changes] = serialized_draft_changeset(the_changes) if track_object_changes_for_draft?
                data = merge_metadata_for_draft(data)

                # If there's already a draft, update it.
                if self.draft?
                  send(self.class.draft_association_name).update(data)

                  if Draftsman.stash_drafted_changes?
                    update_skipped_attributes
                  else
                    self.save
                  end
                # If there's not an existing draft, create an update draft.
                else
                  send("build_#{self.class.draft_association_name}", data)

                  if send(self.class.draft_association_name).save
                    update_column("#{self.class.draft_association_name}_id", send(self.class.draft_association_name).id)

                    if Draftsman.stash_drafted_changes?
                      update_skipped_attributes
                    else
                      self.save
                    end
                  else
                    raise ActiveRecord::Rollback and return false
                  end
                end
              # Otherwise, just save the record.
              else
                self.save
              end
            end
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
            if self.draft? && self.draft.changeset && self.draft.changeset.key?(attr)
              the_changes[attr] = [self.draft.changeset[attr].first, send(attr)]
            else
              the_changes[attr] = [self.send("#{attr}_was"), send(attr)]
            end
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
