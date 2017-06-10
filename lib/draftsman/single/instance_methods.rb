require 'draftsman/shared_instance_methods'

module Draftsman
  module Single
    module InstanceMethods

      include Draftsman::SharedInstanceMethods

      # Returns whether or not this item has a draft.
      def draft?
        send(self.class.draft_association_name).present?
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
              save
            else
              the_changes = changes_for_draftsman(:update)
              save_only_columns_for_draft if Draftsman.stash_drafted_changes?

              # Destroy the draft if this record has changed back to the
              # original values.
              if self.draft? && the_changes.empty?
                nilified_draft = send(self.class.draft_association_name)
                touch = changed?
                send("#{self.class.draft_association_name}_id=", nil)
                save(touch: touch)
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

    end
  end
end
