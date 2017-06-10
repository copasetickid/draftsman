require 'draftsman/shared_instance_methods'

module Draftsman
  module Multiple
    module InstanceMethods

      include Draftsman::SharedInstanceMethods

      # Returns whether or not this item has drafts.
      def has_drafts?
        send(self.class.draft_association_name).count > 0
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

            draft = send(self.class.draft_association_name).new(data)

            if !draft.save
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

            the_changes = changes_for_draftsman(:update)
            save_only_columns_for_draft if Draftsman.stash_drafted_changes?

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
        end
      rescue Exception => e
        logger.error e.message
        logger.error e.backtrace.join("\n")
        false
      end

    end
  end
end
