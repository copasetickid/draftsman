module Draftsman
  module Model

    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      # Declare this in your model to enable the Draftsman API for it. A draft of the model is available in the `draft`
      # association (if one exists).
      #
      # Options:
      #
      # :class_name
      # The name of a custom `Draft` class. This class should inherit from `Draftsman::Draft`. A global default can be
      # set for this using `Draftsman.draft_class_name=` if the default of `Draftsman::Draft` needs to be overridden.
      #
      # :ignore
      # An array of attributes for which an update to a `Draft` will not be stored if they are the only ones changed.
      #
      # :only
      # Inverse of `ignore` - a new `Draft` will be created only for these attributes if supplied. It's recommended that
      # you only specify optional attributes for this (that can be empty).
      #
      # :skip
      # Fields to ignore completely.  As with `ignore`, updates to these fields will not create a new `Draft`. In
      # addition, these fields will not be included in the serialized versions of the object whenever a new `Draft` is
      # created.
      #
      # :meta
      # A hash of extra data to store.  You must add a column to the `drafts` table for each key. Values are objects or
      # `procs` (which are called with `self`, i.e. the model with the `has_drafts`). See
      # `Draftsman::Controller.info_for_draftsman` for an example of how to store data from the controller.
      #
      # :draft
      # The name to use for the `draft` association shortcut method. Default is `:draft`.
      #
      # :published_at
      # The name to use for the method which returns the published timestamp. Default is `published_at`.
      #
      # :trashed_at
      # The name to use for the method which returns the soft delete timestamp. Default is `trashed_at`.
      def has_drafts(options = {})
        # Lazily include the instance methods so we don't clutter up
        # any more ActiveRecord models than we need to.
        send :include, InstanceMethods

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
        belongs_to self.draft_association_name, :class_name => self.draft_class_name, :dependent => :destroy

        # Scopes
        scope :drafted, (lambda do |referenced_table_name = nil|
          referenced_table_name = referenced_table_name.present? ? referenced_table_name : table_name

          if where_not?
            where.not(referenced_table_name => { "#{self.draft_association_name}_id" => nil })
          else
            where("#{referenced_table_name}.#{self.draft_association_name}_id IS NOT NULL")
          end
        end)

        scope :published, (lambda do |referenced_table_name = nil|
          referenced_table_name = referenced_table_name.present? ? referenced_table_name : table_name

          if where_not?
            where.not(referenced_table_name => { self.published_at_attribute_name => nil })
          else
            where("#{self.published_at_attribute_name} IS NOT NULL")
          end
        end)

        scope :trashed, (lambda do |referenced_table_name = nil|
          referenced_table_name = referenced_table_name.present? ? referenced_table_name : table_name

          if where_not?
            where.not(referenced_table_name => { self.trashed_at_attribute_name => nil })
          else
            where("#{self.trashed_at_attribute_name} IS NOT NULL")
          end
        end)

        scope :live, (lambda do |referenced_table_name = nil|
          referenced_table_name = referenced_table_name.present? ? referenced_table_name : table_name
          where(referenced_table_name => { self.trashed_at_attribute_name => nil })
        end)
      end

      # Returns draft class.
      def draft_class
        @draft_class ||= draft_class_name.constantize
      end

      # Returns whether or not `has_drafts` has been called on this model.
      def draftable?
        method_defined?(:draftsman_options)
      end

      # Returns whether or not the included ActiveRecord can do `where.not(...)` style queries.
      def where_not?
        ActiveRecord::VERSION::STRING.to_f >= 4.0
      end

      # Serializes attribute changes for `Draft#object_changes` attribute.
      def serialize_draft_attribute_changes(changes)
        # Don't serialize values before inserting into columns of type `JSON` on PostgreSQL databases.
        return changes if self.draft_class.object_changes_col_is_json?

        serialized_attributes.each do |key, coder|
          if changes.key?(key)
            coder = Draftsman::Serializers::Yaml unless coder.respond_to?(:dump) # Fall back to YAML if `coder` has no `dump` method
            old_value, new_value = changes[key]
            changes[key] = [coder.dump(old_value), coder.dump(new_value)]
          end
        end
      end

      # Used for `Draft#object` attribute
      def serialize_attributes_for_draftsman(attributes)
        # Don't serialize values before inserting into columns of type `JSON` on PostgreSQL databases.
        return attributes if self.draft_class.object_col_is_json?

        serialized_attributes.each do |key, coder|
          if attributes.key?(key)
            coder = Draftsman::Serializers::Yaml unless coder.respond_to?(:dump) # Fall back to YAML if `coder` has no `dump` method
            attributes[key] = coder.dump(attributes[key])
          end
        end
      end

      # Returns whether or not a `trashed_at` timestamp is set up on this model.
      def trashable?
        draftable? && method_defined?(self.trashed_at_attribute_name)
      end

      # Unserializes attribute changes for `Draft#object_changes` attribute.
      def unserialize_draft_attribute_changes(changes)
        # Don't serialize values before inserting into columns of type `JSON` on PostgreSQL databases.
        return changes if self.draft_class.object_changes_col_is_json?

        serialized_attributes.each do |key, coder|
          if changes.key?(key)
            coder = Draftsman::Serializers::Yaml unless coder.respond_to?(:dump)
            old_value, new_value = changes[key]
            changes[key] = [coder.load(old_value), coder.load(new_value)]
          end
        end
      end

      # Used for `Draft#object` attribute
      def unserialize_attributes_for_draftsman(attributes)
        # Don't serialize values before inserting into columns of type `JSON` on PostgreSQL databases.
        return attributes if self.draft_class.object_col_is_json?

        serialized_attributes.each do |key, coder|
          if attributes.key?(key)
            coder = Draftsman::Serializers::Yaml unless coder.respond_to?(:dump)
            attributes[key] = coder.load(attributes[key])
          end
        end
      end
    end

    module InstanceMethods
      # Returns whether or not this item has a draft.
      def draft?
        send(self.class.draft_association_name).present?
      end

      # Creates object and records a draft for the object's creation. Returns `true` or `false` depending on whether or not
      # the objects passed validation and the save was successful.
      def draft_creation
        transaction do
          # We want to save the draft after create
          return false unless self.save

          data = {
            :item      => self,
            :event     => 'create',
            :whodunnit => Draftsman.whodunnit,
            :object    => object_attrs_for_draft_record
          }
          data[:object_changes] = changes_for_draftsman(previous_changes: true) if track_object_changes_for_draft?
          data = merge_metadata_for_draft(data)

          send "build_#{self.class.draft_association_name}", data

          if send(self.class.draft_association_name).save
            write_attribute "#{self.class.draft_association_name}_id", send(self.class.draft_association_name).id
            self.update_column "#{self.class.draft_association_name}_id", send(self.class.draft_association_name).id
            return true
          else
            raise ActiveRecord::Rollback and return false
          end
        end
      end

      # Trashes object and records a draft for a `destroy` event.
      def draft_destroy
        transaction do
          data = {
            :item      => self,
            :event     => 'destroy',
            :whodunnit => Draftsman.whodunnit,
            :object    => object_attrs_for_draft_record
          }

          # Stash previous draft in case it needs to be reverted later
          if self.draft?
            data[:previous_draft] = Draftsman.serializer.dump(send(self.class.draft_association_name).attributes)
          end

          data = merge_metadata_for_draft(data)

          if send(self.class.draft_association_name).present?
            send(self.class.draft_association_name).update_attributes! data
          else
            send("build_#{self.class.draft_association_name}", data)
            send(self.class.draft_association_name).save!
            send "#{self.class.draft_association_name}_id=", send(self.class.draft_association_name).id
            self.update_column "#{self.class.draft_association_name}_id", send(self.class.draft_association_name).id
          end

          trash!

          # Mock `dependent: :destroy` behavior for all trashable associations
          dependent_associations = self.class.reflect_on_all_associations(:has_one) + self.class.reflect_on_all_associations(:has_many)

          dependent_associations.each do |association|

            if association.klass.draftable? && association.options.has_key?(:dependent) && association.options[:dependent] == :destroy
              dependents = association.macro == :has_one ? [self.send(association.name)] : self.send(association.name)

              dependents.each do |dependent|
                dependent.draft_destroy unless dependent.draft? && dependent.send(dependent.class.draft_association_name).destroy?
              end
            end
          end
        end
      end

      # Updates object and records a draft for an `update` event. If the draft is being updated to the object's original
      # state, the draft is destroyed. Returns `true` or `false` depending on if the object passed validation and the save
      # was successful.
      def draft_update
        transaction do
          save_only_columns_for_draft

          # We want to save the draft before update
          return false unless self.valid?

          # If updating a creation draft, also update this item
          if self.draft? && send(self.class.draft_association_name).create?
            data = {
              :item      => self,
              :whodunnit => Draftsman.whodunnit,
              :object    => object_attrs_for_draft_record
            }

            if track_object_changes_for_draft?
              data[:object_changes] = changes_for_draftsman(changed_from: self.send(self.class.draft_association_name).changeset)
            end

            data = merge_metadata_for_draft(data)
            send(self.class.draft_association_name).update_attributes data
            self.save
          # Destroy the draft if this record has changed back to the original record
          elsif changed_to_original_for_draft?
            send(self.class.draft_association_name).destroy
            send "#{self.class.draft_association_name}_id=", nil
            self.save
          # Save a draft if record is changed notably
          elsif changed_notably_for_draft?
            data = {
              :item      => self,
              :whodunnit => Draftsman.whodunnit,
              :object    => object_attrs_for_draft_record
            }
            data = merge_metadata_for_draft(data)

            # If there's already a draft, update it.
            if send(self.class.draft_association_name).present?
              data[:object_changes] = changes_for_draftsman if track_object_changes_for_draft?
              send(self.class.draft_association_name).update_attributes data
            # If there's not draft, create an update draft.
            else
              data[:event]          = 'update'
              data[:object_changes] = changes_for_draftsman if track_object_changes_for_draft?
              send "build_#{self.class.draft_association_name}", data
              
              if send(self.class.draft_association_name).save
                update_column "#{self.class.draft_association_name}_id", send(self.class.draft_association_name).id
                update_skipped_attributes
              else
                raise ActiveRecord::Rollback and return false
              end
            end
          # If record is a draft and not changed notably, then update the draft.
          elsif self.draft?
            data = {
              :item      => self,
              :whodunnit => Draftsman.whodunnit,
              :object    => object_attrs_for_draft_record
            }
            data[:object_changes] = changes_for_draftsman(changed_from: @object.draft.changeset) if track_object_changes_for_draft?
            data = merge_metadata_for_draft(data)
            send(self.class.draft_association_name).update_attributes data
            update_skipped_attributes
          # Otherwise, just save the record
          else
            self.save
          end
        end
      rescue Exception => e
        false
      end

      # Returns serialized object representing this drafted item.
      def object_attrs_for_draft_record(object = nil)
        object ||= self

        _attrs = object.attributes.except(*self.class.draftsman_options[:skip]).tap do |attributes|
          self.class.serialize_attributes_for_draftsman attributes
        end

        self.class.draft_class.object_col_is_json? ? _attrs : Draftsman.serializer.dump(_attrs)
      end

      # Returns whether or not this item has been published at any point in its lifecycle.
      def published?
        self.published_at.present?
      end

      # Returns whether or not this item has been trashed
      def trashed?
        send(self.class.trashed_at_attribute_name).present?
      end

    private

      # Returns changes on this object, excluding attributes defined in the options for `:ignore` and `:skip`.
      def changed_and_not_ignored_for_draft(options = {})
        options[:previous_changes] ||= false

        my_changed = options[:previous_changes] ? previous_changes.keys : self.changed

        ignore = self.class.draftsman_options[:ignore]
        skip   = self.class.draftsman_options[:skip]
        my_changed - ignore - skip
      end

      # Returns whether or not this instance has changes that should trigger a new draft.
      def changed_notably_for_draft?
        notably_changed_attributes_for_draft.any?
      end

      # Returns whether or not the updates change this draft back to the original state
      def changed_to_original_for_draft?
        send(self.draft_association_name).present? && send(self.class.draft_association_name).update? && !changed_notably_for_draft?
      end

      # Returns array of attributes that have changed for the object.
      def changes_for_draftsman(options = {})
        options[:changed_from]     ||= {}
        options[:previous_changes] ||= false

        my_changes = options[:previous_changes] ? self.previous_changes : self.changes

        new_changes = my_changes.delete_if do |key, value|
          !notably_changed_attributes_for_draft(previous_changes: options[:previous_changes]).include?(key)
        end.tap do |changes|
          self.class.serialize_draft_attribute_changes(changes) # Use serialized value for attributes when necessary
        end

        new_changes.each do |attribute, value|
          new_changes[attribute][0] = options[:changed_from][attribute][0] if options[:changed_from].has_key?(attribute)
        end

        # We need to merge any previous changes so they are not lost on further updates before committing or
        # reverting
        my_changes = options[:changed_from].merge new_changes

        self.class.draft_class.object_changes_col_is_json? ? my_changes : Draftsman.serializer.dump(my_changes)
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

      # Returns array of attributes that were changed to trigger a draft.
      def notably_changed_attributes_for_draft(options = {})
        options[:previous_changes] ||= false

        only = self.class.draftsman_options[:only]
        only.empty? ? changed_and_not_ignored_for_draft(previous_changes: options[:previous_changes]) : (changed_and_not_ignored_for_draft(previous_changes: options[:previous_changes]) & only)
      end

      # Save columns outside of the `only` option directly to master table
      def save_only_columns_for_draft
        if self.class.draftsman_options[:only].any?
          only_changes = {}
          only_changed_attributes = self.changed - self.class.draftsman_options[:only]
          
          only_changed_attributes.each do |attribute|
            only_changes[attribute] = self.changes[attribute].last
          end

          self.update_columns only_changes if only_changes.any?
        end
      end

      # Returns whether or not the draft class includes an `object_changes` attribute.
      def track_object_changes_for_draft?
        self.class.draft_class.column_names.include? 'object_changes'
      end

      # Sets `trashed_at` attribute to now and saves to the database immediately.
      def trash!
        write_attribute self.class.trashed_at_attribute_name, Time.now
        self.update_column self.class.trashed_at_attribute_name, send(self.class.trashed_at_attribute_name)
      end

      # Updates skipped attributes' values on this model.
      def update_skipped_attributes
        if draftsman_options[:skip].present?
          changed_and_skipped_keys = self.changed.select { |key| draftsman_options[:skip].include?(key) }
          changed_and_skipped_attrs = {}
          changed_and_skipped_keys.each { |key| changed_and_skipped_attrs[key] = self.changes[key].last }

          self.reload
          self.attributes = changed_and_skipped_attrs
          self.save
        else
          true
        end
      end
    end
  end
end
