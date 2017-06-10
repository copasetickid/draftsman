module Draftsman
  module SharedInstanceMethods

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
          if self.multiple
            the_changes[attr] = [self.send("#{attr}_was"), send(attr)]
          else
            if self.draft? && self.draft.changeset && self.draft.changeset.key?(attr)
              the_changes[attr] = [self.draft.changeset[attr].first, send(attr)]
            else
              the_changes[attr] = [self.send("#{attr}_was"), send(attr)]
            end
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
      skipped_changed = changed_attributes.keys & draftsman_options[:skip]
      return true unless skipped_changed.present?

      keys = self.attributes.keys.select { |key| draftsman_options[:skip].include?(key) }
      attrs = {}
      keys.each { |key| attrs[key] = self.send(key) }

      self.reload
      self.update(attrs)
    end
  end
end
