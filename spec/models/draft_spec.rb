require 'spec_helper'

describe Draftsman::Draft do
  let(:trashable) { Trashable.new(name: 'Bob') }

  describe '.object_col_is_json?' do
    it 'does not have a JSON object column' do
      expect(Draftsman::Draft.object_col_is_json?).to eql false
    end
  end

  describe '.object_changes_col_is_json?' do
    it 'does not have a JSON object_changes column' do
      expect(Draftsman::Draft.object_changes_col_is_json?).to eql false
    end
  end

  describe '.previous_draft_col_is_json?' do
    it 'does not have a JSON previous_draft column' do
      expect(Draftsman::Draft.previous_draft_col_is_json?).to eql false
    end
  end

  describe '#event, #create?, #update?, #destroy?, #changeset' do
    context 'with `create` draft' do
      before { trashable.save_draft }

      it 'is a `create` event' do
        expect(trashable.draft.event).to eql 'create'
      end

      it 'identifies as a `create` event' do
        expect(trashable.draft.create?).to eql true
      end

      it 'does not identify as an `update` event' do
        expect(trashable.draft.update?).to eql false
      end

      it 'does not identify as a `destroy` event' do
        expect(trashable.draft.destroy?).to eql false
      end

      it 'has an `id` in the `changeset`' do
        expect(trashable.draft.changeset).to include :id
      end

      it 'has a `name` in the `changeset`' do
        expect(trashable.draft.changeset).to include :name
      end

      it 'does not have a `title` in the `changeset`' do
        expect(trashable.draft.changeset).to_not include :title
      end

      it 'has `created_at` in the `changeset`' do
        expect(trashable.draft.changeset).to include :created_at
      end

      it 'has `updated_at` in the `changeset`' do
        expect(trashable.draft.changeset).to include :updated_at
      end

      it 'does not have a `previous_draft`' do
        expect(trashable.draft.previous_draft).to be_nil
      end

      context 'updated create' do
        before do
          trashable.name = 'Sam'
          trashable.save_draft
        end

        it 'identifies as a `create` event' do
          expect(trashable.draft.create?).to eql true
        end

        it 'does not identify as an `update` event' do
          expect(trashable.draft.update?).to eql false
        end

        it 'does not identify as a `destroy` event' do
          expect(trashable.draft.destroy?).to eql false
        end

        it 'is a `create` event' do
          expect(trashable.draft.event).to eql 'create'
        end

        it 'has an `id` in the `changeset`' do
          expect(trashable.draft.changeset).to include :id
        end

        it 'has a `name` in the `changeset`' do
          expect(trashable.draft.changeset).to include :name
        end

        it 'does not have a `title` in the `changeset`' do
          expect(trashable.draft.changeset).to_not include :title
        end

        it 'has `created_at` in the `changeset`' do
          expect(trashable.draft.changeset).to include :created_at
        end

        it 'has `updated_at` in the `changeset`' do
          expect(trashable.draft.changeset).to include :updated_at
        end

        it 'does not have a `previous_draft`' do
          expect(trashable.draft.previous_draft).to be_nil
        end
      end
    end

    context 'with `update` draft' do
      before do
        trashable.save!
        trashable.name = 'Sam'
        trashable.title = 'My Title'
        trashable.save_draft
      end

      it 'does not identify as a `create` event' do
        expect(trashable.draft.create?).to eql false
      end

      it 'identifies as an `update event' do
        expect(trashable.draft.update?).to eql true
      end

      it 'does not identify as a `destroy` event' do
        expect(trashable.draft.destroy?).to eql false
      end

      it 'has an `update` event' do
        expect(trashable.draft.event).to eql 'update'
      end

      it 'does not have an `id` in the `changeset`' do
        expect(trashable.draft.changeset).to_not include :id
      end

      it 'has a `name` in the `changeset`' do
        expect(trashable.draft.changeset).to include :name
      end

      it 'has a `title` in the `changeset`' do
        expect(trashable.draft.changeset).to include :title
      end

      it 'does not have `created_at` in the `changeset`' do
        expect(trashable.draft.changeset).to_not include :created_at
      end

      it 'does not have `updated_at` in the `changeset`' do
        expect(trashable.draft.changeset).to_not include :updated_at
      end

      it 'does not have a `previous_draft`' do
        expect(trashable.draft.previous_draft).to be_nil
      end

      context 'updating the update' do
        before do
          trashable.title = nil
          trashable.save_draft
          trashable.reload
        end

        it 'does not identify as a `create` event' do
          expect(trashable.draft.create?).to eql false
        end

        it 'identifies as an `update` event' do
          expect(trashable.draft.update?).to eql true
        end

        it 'does not identify as a `destroy` event' do
          expect(trashable.draft.destroy?).to eql false
        end

        it 'has an `update` event' do
          expect(trashable.draft.event).to eql 'update'
        end

        it 'does not have an `id` in the `changeset`' do
          expect(trashable.draft.changeset).to_not include :id
        end

        it 'has a `name` in the `changeset`' do
          expect(trashable.draft.changeset).to include :name
        end

        it 'does not have a `title` in the `changeset`' do
          expect(trashable.draft.changeset).to_not include :title
        end

        it 'does not have `created_at` in the `changeset`' do
          expect(trashable.draft.changeset).to_not include :created_at
        end

        it 'does not have `updated_at` in the `changeset`' do
          expect(trashable.draft.changeset).to_not include :updated_at
        end

        it 'does not have a `previous_draft`' do
          expect(trashable.draft.previous_draft).to be_nil
        end
      end
    end

    context 'with `destroy` draft' do
      context 'without previous draft' do
        before do
          trashable.save!
          trashable.draft_destruction
        end

        it 'does not identify as a `create` event' do
          expect(trashable.draft.create?).to eql false
        end

        it 'does not identify as an `update` event' do
          expect(trashable.draft.update?).to eql false
        end

        it 'identifies as a `destroy` event' do
          expect(trashable.draft.destroy?).to eql true
        end

        it 'is not destroyed' do
          expect(trashable.draft.destroyed?).to eql false
        end

        it 'is a `destroy` event' do
          expect(trashable.draft.event).to eql 'destroy'
        end

        it 'has an empty `changeset`' do
          expect(trashable.draft.changeset).to eql Hash.new
        end

        it 'does not have a `previous_draft`' do
          expect(trashable.draft.previous_draft).to be_nil
        end
      end

      context 'with previous `create` draft' do
        before do
          trashable.save_draft
          trashable.draft_destruction
        end

        it 'does not identify as a `create` event' do
          expect(trashable.draft.create?).to eql false
        end

        it 'does not identify as an `update` event' do
          expect(trashable.draft.update?).to eql false
        end

        it 'identifies as a `destroy` event' do
          expect(trashable.draft.destroy?).to eql true
        end

        it 'is not destroyed' do
          expect(trashable.draft.destroyed?).to eql false
        end

        it 'is a `destroy` event' do
          expect(trashable.draft.event).to eql 'destroy'
        end

        it 'has an `id` in the `changeset`' do
          expect(trashable.draft.changeset).to include :id
        end

        it 'has a `name` in the `changeset`' do
          expect(trashable.draft.changeset).to include :name
        end

        it 'does not have a `title` in the `changeset`' do
          expect(trashable.draft.changeset).to_not include :title
        end

        it 'has `created_at` in the `changeset`' do
          expect(trashable.draft.changeset).to include :created_at
        end

        it 'has `updated_at` in the `changeset`' do
          expect(trashable.draft.changeset).to include :updated_at
        end

        it 'has a `previous_draft`' do
          expect(trashable.draft.previous_draft).to be_present
        end
      end
    end
  end # #event, #create?, #update?, #destroy?, #changeset

  describe '#object' do
    context 'with stashed drafted changes' do
      context 'with `create` draft' do
        before { trashable.save_draft }

        it 'has an object' do
          expect(trashable.draft.object).to be_present
        end

        context 'updated create' do
          before do
            trashable.name = 'Sam'
            trashable.save_draft
          end

          it 'has an `object`' do
            expect(trashable.draft.object).to be_present
          end
        end
      end

      context 'with `update` draft' do
        before do
          trashable.save!
          trashable.name = 'Sam'
          trashable.title = 'My Title'
          trashable.save_draft
        end

        it 'has an `object`' do
          expect(trashable.draft.object).to be_present
        end

        context 'updating the update' do
          before do
            trashable.title = nil
            trashable.save_draft
          end

          it 'has an `object`' do
            expect(trashable.draft.object).to be_present
          end
        end
      end

      context 'with `destroy` draft' do
        context 'without previous draft' do
          before do
            trashable.save!
            trashable.draft_destruction
          end

          it 'has an `object`' do
            expect(trashable.draft.object).to be_present
          end
        end

        context 'with previous `create` draft' do
          before do
            trashable.save_draft
            trashable.draft_destruction
          end

          it 'has an `object`' do
            expect(trashable.draft.object).to be_present
          end
        end
      end
    end # with stashed drafted changes

    context 'without stashed drafted changes' do
      before { Draftsman.stash_drafted_changes = false }
      after { Draftsman.stash_drafted_changes = true }

      context 'with `create` draft' do
        before { trashable.save_draft }

        it 'has no object' do
          expect(trashable.draft.object).to be_nil
        end

        context 'updated create' do
          before do
            trashable.name = 'Sam'
            trashable.save_draft
            trashable.reload
          end

          it 'has no `object`' do
            expect(trashable.draft.object).to be_nil
          end
        end
      end

      context 'with `update` draft' do
        before do
          trashable.save!
          trashable.name = 'Sam'
          trashable.title = 'My Title'
          trashable.save_draft
          trashable.reload
        end

        it 'has no `object`' do
          expect(trashable.draft.object).to be_nil
        end

        context 'updating the update' do
          before do
            trashable.title = nil
            trashable.save_draft
          end

          it 'has no `object`' do
            expect(trashable.draft.object).to be_nil
          end
        end
      end

      context 'with `destroy` draft' do
        context 'without previous draft' do
          before do
            trashable.save!
            trashable.draft_destruction
          end

          it 'has no `object`' do
            expect(trashable.draft.object).to be_nil
          end
        end

        context 'with previous `create` draft' do
          before do
            trashable.save_draft
            trashable.draft_destruction
          end

          it 'has no `object`' do
            expect(trashable.draft.object).to be_nil
          end
        end
      end
    end # without stashed drafted changes
  end # #object

  describe '#whodunnit' do
    context 'with default `whodunnit` field name' do
      it 'records value in `whodunnit`' do
        ::Draftsman.whodunnit = :foobar
        trashable.save_draft
        expect(trashable.reload.draft.whodunnit).to eql 'foobar'
      end
    end

    context 'with custom `user_id` field' do
      before { ::Draftsman.whodunnit_field = :user_id }
      after { ::Draftsman.whodunnit_field = :whodunnit }

      it 'records value in `user_id`' do
        ::Draftsman.whodunnit = 4321
        trashable.save_draft
        expect(trashable.reload.draft.user_id).to eql 4321
      end

      it 'does not record value in `whodunnit`' do
        ::Draftsman.whodunnit_field = :user_id
        ::Draftsman.whodunnit = :foobar
        trashable.save_draft
        expect(trashable.reload.draft.whodunnit).to be_nil
        ::Draftsman.whodunnit_field = :whodunnit
      end
    end
  end

  describe '#publish!' do
    context 'with stashed drafted changes' do
      context 'with `create` draft' do
        before { trashable.save_draft }

        it 'does not raise an exception' do
          expect { trashable.draft.publish! }.to_not raise_exception
        end

        it 'publishes the item' do
          trashable.draft.publish!
          expect(trashable.reload.published?).to eql true
        end

        it 'is not trashed' do
          trashable.draft.publish!
          expect(trashable.reload.trashed?).to eql false
        end

        it 'is no longer a draft' do
          trashable.draft.publish!
          expect(trashable.reload.draft?).to eql false
        end

        it 'should have a `published_at` timestamp' do
          trashable.draft.publish!
          expect(trashable.reload.published_at).to be_present
        end

        it 'does not have a `draft_id`' do
          trashable.draft.publish!
          expect(trashable.reload.draft_id).to be_nil
        end

        it 'does not have a draft' do
          trashable.draft.publish!
          expect(trashable.reload.draft).to be_nil
        end

        it 'does not have a `trashed_at` timestamp' do
          trashable.draft.publish!
          expect(trashable.reload.trashed_at).to be_nil
        end

        it 'deletes the draft record' do
          expect { trashable.draft.publish! }.to change(Draftsman::Draft, :count).by(-1)
        end
      end # with `create` draft

      context 'with `update` draft' do
        before do
          trashable.save!
          trashable.name = 'Sam'
          trashable.save_draft
        end

        it 'does not raise an exception' do
          expect { trashable.draft.publish! }.to_not raise_exception
        end

        it 'publishes the item' do
          trashable.draft.publish!
          expect(trashable.reload.published?).to eql true
        end

        it 'is no longer a draft' do
          trashable.draft.publish!
          expect(trashable.reload.draft?).to eql false
        end

        it 'is not trashed' do
          trashable.draft.publish!
          expect(trashable.reload.trashed?).to eql false
        end

        it 'has an updated `name`' do
          trashable.draft.publish!
          expect(trashable.reload.name).to eql 'Sam'
        end

        it 'has a `published_at` timestamp' do
          trashable.draft.publish!
          expect(trashable.reload.published_at).to be_present
        end

        it 'does not have a `draft_id`' do
          trashable.draft.publish!
          expect(trashable.reload.draft_id).to be_nil
        end

        it 'does not have a `draft`' do
          trashable.draft.publish!
          expect(trashable.reload.draft).to be_nil
        end

        it 'does not have a `trashed_at` timestamp' do
          trashable.draft.publish!
          expect(trashable.reload.trashed_at).to be_nil
        end

        it 'destroys the draft' do
          expect { trashable.draft.publish! }.to change(Draftsman::Draft, :count).by(-1)
        end

        it 'does not delete the associated item' do
          expect { trashable.draft.publish! }.to_not change(Trashable, :count)
        end
      end # with `update` draft

      context 'with `destroy` draft' do
        context 'without previous draft' do
          before do
            trashable.save!
            trashable.draft_destruction
          end

          it 'destroys the draft' do
            expect { trashable.draft.publish! }.to change(Draftsman::Draft, :count).by(-1)
          end

          it 'deletes the associated item' do
            expect { trashable.draft.publish! }.to change(Trashable, :count).by(-1)
          end
        end

        context 'with previous `create` draft' do
          before do
            trashable.save_draft
            trashable.draft_destruction
          end

          it 'destroys the draft' do
            expect { trashable.draft.publish! }.to change(Draftsman::Draft, :count).by(-1)
          end

          it 'deletes the associated item' do
            expect { trashable.draft.publish! }.to change(Trashable, :count).by(-1)
          end
        end
      end
    end # with stashed drafted changes

    context 'without stashed drafted changes' do
      before { Draftsman.stash_drafted_changes = false }
      after { Draftsman.stash_drafted_changes = true }

      context 'with `create` draft' do
        before { trashable.save_draft }

        it 'does not raise an exception' do
          expect { trashable.draft.publish! }.to_not raise_exception
        end

        it 'publishes the item' do
          trashable.draft.publish!
          expect(trashable.reload.published?).to eql true
        end

        it 'is not trashed' do
          trashable.draft.publish!
          expect(trashable.reload.trashed?).to eql false
        end

        it 'is no longer a draft' do
          trashable.draft.publish!
          expect(trashable.reload.draft?).to eql false
        end

        it 'should have a `published_at` timestamp' do
          trashable.draft.publish!
          expect(trashable.reload.published_at).to be_present
        end

        it 'does not have a `draft_id`' do
          trashable.draft.publish!
          expect(trashable.reload.draft_id).to be_nil
        end

        it 'does not have a draft' do
          trashable.draft.publish!
          expect(trashable.reload.draft).to be_nil
        end

        it 'does not have a `trashed_at` timestamp' do
          trashable.draft.publish!
          expect(trashable.reload.trashed_at).to be_nil
        end

        it 'deletes the draft record' do
          expect { trashable.draft.publish! }.to change(Draftsman::Draft, :count).by(-1)
        end
      end

      context 'with `update` draft' do
        before do
          trashable.save!
          trashable.name = 'Sam'
          trashable.save_draft
        end

        it 'does not raise an exception' do
          expect { trashable.draft.publish! }.to_not raise_exception
        end

        it 'publishes the item' do
          trashable.draft.publish!
          expect(trashable.reload.published?).to eql true
        end

        it 'is no longer a draft' do
          trashable.draft.publish!
          expect(trashable.reload.draft?).to eql false
        end

        it 'is not trashed' do
          trashable.draft.publish!
          expect(trashable.reload.trashed?).to eql false
        end

        it 'has an updated `name`' do
          trashable.draft.publish!
          expect(trashable.reload.name).to eql 'Sam'
        end

        it 'has a `published_at` timestamp' do
          trashable.draft.publish!
          expect(trashable.reload.published_at).to be_present
        end

        it 'does not have a `draft_id`' do
          trashable.draft.publish!
          expect(trashable.reload.draft_id).to be_nil
        end

        it 'does not have a `draft`' do
          trashable.draft.publish!
          expect(trashable.reload.draft).to be_nil
        end

        it 'does not have a `trashed_at` timestamp' do
          trashable.draft.publish!
          expect(trashable.reload.trashed_at).to be_nil
        end

        it 'destroys the draft' do
          expect { trashable.draft.publish! }.to change(Draftsman::Draft, :count).by(-1)
        end

        it 'does not delete the associated item' do
          expect { trashable.draft.publish! }.to_not change(Trashable, :count)
        end
      end

      context 'with `destroy` draft' do
        context 'without previous draft' do
          before do
            trashable.save!
            trashable.draft_destruction
          end

          it 'destroys the draft' do
            expect { trashable.draft.publish! }.to change(Draftsman::Draft, :count).by(-1)
          end

          it 'deletes the associated item' do
            expect { trashable.draft.publish! }.to change(Trashable, :count).by(-1)
          end
        end

        context 'with previous `create` draft' do
          before do
            trashable.save_draft
            trashable.draft_destruction
          end

          it 'destroys the draft' do
            expect { trashable.draft.publish! }.to change(Draftsman::Draft, :count).by(-1)
          end

          it 'deletes the associated item' do
            expect { trashable.draft.publish! }.to change(Trashable, :count).by(-1)
          end
        end
      end
    end # without stashed draft changes
  end # #publish!

  describe '#revert!' do
    context 'with stashed draft changes' do
      context 'with `create` draft' do
        before { trashable.save_draft }

        it 'does not raise an exception' do
          expect { trashable.draft.revert! }.to_not raise_exception
        end

        it 'destroys the draft' do
          expect { trashable.draft.revert! }.to change(Draftsman::Draft, :count).by(-1)
        end

        it 'destroys associated item' do
          expect { trashable.draft.revert! }.to change(Trashable, :count).by(-1)
        end
      end

      context 'with `update` draft' do
        before do
          trashable.save!
          trashable.name = 'Sam'
          trashable.save_draft
        end

        it 'does not raise an exception' do
          expect { trashable.draft.revert! }.to_not raise_exception
        end

        it 'is no longer a draft' do
          trashable.draft.revert!
          expect(trashable.reload.draft?).to eql false
        end

        it 'reverts its `name`' do
          trashable.draft.revert!
          expect(trashable.reload.name).to eql 'Bob'
        end

        it 'does not have a `draft_id`' do
          trashable.draft.revert!
          expect(trashable.reload.draft_id).to be_nil
        end

        it 'does not have a `draft`' do
          trashable.draft.revert!
          expect(trashable.reload.draft).to be_nil
        end

        it 'destroys the draft record' do
          expect { trashable.draft.revert! }.to change(Draftsman::Draft, :count).by(-1)
        end

        it 'does not destroy the associated item' do
          expect { trashable.draft.revert! }.to_not change(Trashable, :count)
        end
      end # with `update` draft

      context 'with `destroy` draft' do
        context 'without previous draft' do
          before do
            trashable.save!
            trashable.draft_destruction
          end

          it 'does not raise an exception' do
            expect { trashable.draft.revert! }.to_not raise_exception
          end

          it 'is not trashed' do
            trashable.draft.revert!
            expect(trashable.reload.trashed?).to eql false
          end

          it 'is no longer a draft' do
            trashable.draft.revert!
            expect(trashable.reload.draft?).to eql false
          end

          it 'does not have a `draft_id`' do
            trashable.draft.revert!
            expect(trashable.reload.draft_id).to be_nil
          end

          it 'does not have a `draft`' do
            trashable.draft.revert!
            expect(trashable.reload.draft).to be_nil
          end

          it 'does not have a `trashed_at` timestamp' do
            trashable.draft.revert!
            expect(trashable.reload.trashed_at).to be_nil
          end

          it 'destroys the draft record' do
            expect { trashable.draft.revert! }.to change(Draftsman::Draft, :count).by(-1)
          end

          it 'does not destroy the associated item' do
            expect { trashable.draft.revert! }.to_not change(Trashable, :count)
          end
        end # without previous draft

        context 'with previous `create` draft' do
          before do
            trashable.save_draft
            trashable.draft_destruction
          end

          it 'does not raise an exception' do
            expect { trashable.draft.revert! }.to_not raise_exception
          end

          it 'is not trashed' do
            trashable.draft.revert!
            expect(trashable.reload.trashed?).to eql false
          end

          it 'is a draft' do
            trashable.draft.revert!
            expect(trashable.reload.draft?).to eql true
          end

          it 'has a `draft_id`' do
            trashable.draft.revert!
            expect(trashable.reload.draft_id).to be_present
          end

          it 'has a `draft`' do
            trashable.draft.revert!
            expect(trashable.reload.draft).to be_present
          end

          it 'does not have a `trashed_at` timestamp' do
            trashable.draft.revert!
            expect(trashable.reload.trashed_at).to be_nil
          end

          it 'destroys the `destroy` draft record' do
            expect { trashable.draft.revert! }.to change(Draftsman::Draft.where(event: :destroy), :count).by(-1)
          end

          it 'reifies the previous `create` draft record' do
            expect { trashable.draft.revert! }.to change(Draftsman::Draft.where(event: :create), :count).by(1)
          end

          it 'does not destroy the associated item' do
            expect { trashable.draft.revert! }.to_not change(Trashable, :count)
          end

          it "no longer has a `previous_draft`" do
            trashable.draft.revert!
            expect(trashable.reload.draft.previous_draft).to be_nil
          end
        end # with previous `create` draft
      end # with `destroy` draft
    end # with stashed draft changes

    context 'without stashed draft changes' do
      before { Draftsman.stash_drafted_changes = false }
      after { Draftsman.stash_drafted_changes = true }

      context 'with `create` draft' do
        before { trashable.save_draft }

        it 'does not raise an exception' do
          expect { trashable.draft.revert! }.to_not raise_exception
        end

        it 'destroys the draft' do
          expect { trashable.draft.revert! }.to change(Draftsman::Draft, :count).by(-1)
        end

        it 'destroys associated item' do
          expect { trashable.draft.revert! }.to change(Trashable, :count).by(-1)
        end
      end

      context 'with `update` draft' do
        before do
          trashable.save!
          trashable.name = 'Sam'
          trashable.save_draft
        end

        it 'does not raise an exception' do
          expect { trashable.draft.revert! }.to_not raise_exception
        end

        it 'is no longer a draft' do
          trashable.draft.revert!
          expect(trashable.reload.draft?).to eql false
        end

        it 'reverts its `name`' do
          trashable.draft.revert!
          expect(trashable.reload.name).to eql 'Bob'
        end

        it 'does not have a `draft_id`' do
          trashable.draft.revert!
          expect(trashable.reload.draft_id).to be_nil
        end

        it 'does not have a `draft`' do
          trashable.draft.revert!
          expect(trashable.reload.draft).to be_nil
        end

        it 'destroys the draft record' do
          expect { trashable.draft.revert! }.to change(Draftsman::Draft, :count).by(-1)
        end

        it 'does not destroy the associated item' do
          expect { trashable.draft.revert! }.to_not change(Trashable, :count)
        end
      end # with `update` draft

      context 'with `destroy` draft' do
        context 'without previous draft' do
          before do
            trashable.save!
            trashable.draft_destruction
          end

          it 'does not raise an exception' do
            expect { trashable.draft.revert! }.to_not raise_exception
          end

          it 'is not trashed' do
            trashable.draft.revert!
            expect(trashable.reload.trashed?).to eql false
          end

          it 'is no longer a draft' do
            trashable.draft.revert!
            expect(trashable.reload.draft?).to eql false
          end

          it 'does not have a `draft_id`' do
            trashable.draft.revert!
            expect(trashable.reload.draft_id).to be_nil
          end

          it 'does not have a `draft`' do
            trashable.draft.revert!
            expect(trashable.reload.draft).to be_nil
          end

          it 'does not have a `trashed_at` timestamp' do
            trashable.draft.revert!
            expect(trashable.reload.trashed_at).to be_nil
          end

          it 'destroys the draft record' do
            expect { trashable.draft.revert! }.to change(Draftsman::Draft, :count).by(-1)
          end

          it 'does not destroy the associated item' do
            expect { trashable.draft.revert! }.to_not change(Trashable, :count)
          end
        end # without previous draft

        context 'with previous `create` draft' do
          before do
            trashable.save_draft
            trashable.draft_destruction
          end

          it 'does not raise an exception' do
            expect { trashable.draft.revert! }.to_not raise_exception
          end

          it 'is not trashed' do
            trashable.draft.revert!
            expect(trashable.reload.trashed?).to eql false
          end

          it 'is a draft' do
            trashable.draft.revert!
            expect(trashable.reload.draft?).to eql true
          end

          it 'has a `draft_id`' do
            trashable.draft.revert!
            expect(trashable.reload.draft_id).to be_present
          end

          it 'has a `draft`' do
            trashable.draft.revert!
            expect(trashable.reload.draft).to be_present
          end

          it 'does not have a `trashed_at` timestamp' do
            trashable.draft.revert!
            expect(trashable.reload.trashed_at).to be_nil
          end

          it 'destroys the `destroy` draft record' do
            expect { trashable.draft.revert! }.to change(Draftsman::Draft.where(event: :destroy), :count).by(-1)
          end

          it 'reifies the previous `create` draft record' do
            expect { trashable.draft.revert! }.to change(Draftsman::Draft.where(event: :create), :count).by(1)
          end

          it 'does not destroy the associated item' do
            expect { trashable.draft.revert! }.to_not change(Trashable, :count)
          end

          it "no longer has a `previous_draft`" do
            trashable.draft.revert!
            expect(trashable.reload.draft.previous_draft).to be_nil
          end
        end # with previous `create` draft
      end # with `destroy` draft
    end # without stashed draft changes
  end # #revert!

  describe '#reify' do
    context 'with `create` draft' do
      before { trashable.save_draft }

      it "has a `title` that matches the item's" do
        expect(trashable.draft.reify.title).to eql trashable.title
      end

      context 'updated create' do
        before do
          trashable.name = 'Sam'
          trashable.save_draft
        end

        it 'has an updated `name`' do
          expect(trashable.draft.reify.name).to eql 'Sam'
        end

        it 'has no `title`' do
          expect(trashable.draft.reify.title).to be_nil
        end
      end
    end

    context 'with `update` draft' do
      before do
        trashable.save!
        trashable.name = 'Sam'
        trashable.title = 'My Title'
        trashable.save_draft
      end

      it 'has the updated `name`' do
        expect(trashable.draft.reify.name).to eql 'Sam'
      end

      it 'has the updated `title`' do
        expect(trashable.draft.reify.title).to eql 'My Title'
      end

      context 'updating the update' do
        before do
          trashable.title = nil
          trashable.save_draft
          trashable.reload
        end

        it 'has the same `name`' do
          expect(trashable.draft.reify.name).to eql 'Sam'
        end

        it 'has the updated `title`' do
          expect(trashable.draft.reify.title).to be_nil
        end
      end
    end

    context 'with `destroy` draft' do
      context 'without previous draft' do
        before do
          trashable.save!
          trashable.draft_destruction
        end

        it 'records the `name`' do
          expect(trashable.draft.reify.name).to eql 'Bob'
        end

        it 'records the `title`' do
          expect(trashable.draft.reify.title).to be_nil
        end
      end

      context 'with previous `create` draft' do
        before do
          trashable.save_draft
          trashable.draft_destruction
        end

        it 'records the `name`' do
          expect(trashable.draft.reify.name).to eql 'Bob'
        end

        it 'records the `title`' do
          expect(trashable.draft.reify.title).to be_nil
        end
      end

      context 'with previous `update` draft' do
        before do
          trashable.save!
          trashable.name = 'Sam'
          trashable.title = 'My Title'
          trashable.save_draft
          # Typically, 2 draft operations won't happen in the same request, so
          # reload before draft-destroying.
          trashable.reload.draft_destruction
        end

        it 'records the updated `name`' do
          expect(trashable.draft.reify.name).to eql 'Sam'
        end

        it 'records the updated `title`' do
          expect(trashable.draft.reify.title).to eql 'My Title'
        end
      end
    end
  end # #reify

  describe '#draft_publication_dependencies' do
    context 'with stashed draft changes' do
      context 'with publication dependency' do
        let(:parent) { Parent.new(name: 'Marge') }
        let(:child)  { Child.new(name: 'Lisa', parent: parent) }

        before do
          parent.save_draft
          child.save_draft
        end

        it 'returns the parent' do
          expect(child.draft.draft_publication_dependencies.to_a).to eql [parent.draft]
        end
      end

      context 'without publication dependency' do
        let(:parent) { Parent.new(name: 'Marge') }
        let(:child)  { Child.new(name: 'Lisa', parent: parent) }

        before do
          parent.save_draft
          child.save_draft
        end

        it 'returns the parent' do
          expect(parent.draft.draft_publication_dependencies.to_a).to eql []
        end
      end
    end

    context 'without stashed drafted changes' do
      before { Draftsman.stash_drafted_changes = false }
      after { Draftsman.stash_drafted_changes = true }

      context 'with publication dependency' do
        let(:parent) { Parent.new(name: 'Marge') }
        let(:child)  { Child.new(name: 'Lisa', parent: parent) }

        before do
          parent.save_draft
          child.save_draft
        end

        it 'returns the parent' do
          expect(child.draft.draft_publication_dependencies.to_a).to eql [parent.draft]
        end
      end

      context 'without publication dependency' do
        let(:parent) { Parent.new(name: 'Marge') }
        let(:child)  { Child.new(name: 'Lisa', parent: parent) }

        before do
          parent.save_draft
          child.save_draft
        end

        it 'returns the parent' do
          expect(parent.draft.draft_publication_dependencies.to_a).to eql []
        end
      end
    end
  end # #draft_publication_dependencies

  describe '#draft_reversion_dependencies' do
    context 'with stashed draft changes' do
      let(:parent) { Parent.new(name: 'Marge') }
      let(:child)  { Child.new(name: 'Lisa', parent: parent) }

      before do
        parent.save_draft
        child.save_draft
      end

      context 'with reversion dependency' do
        it 'returns the parent' do
          expect(parent.draft.draft_reversion_dependencies).to eql [child.draft]
        end
      end

      context 'without reversion dependency' do
        it 'returns the parent' do
          expect(child.draft.draft_reversion_dependencies).to eql []
        end
      end
    end

    context 'without stashed drafted changes' do
      let(:parent) { Parent.new(name: 'Marge') }
      let(:child)  { Child.new(name: 'Lisa', parent: parent) }

      before do
        Draftsman.stash_drafted_changes = false
        parent.save_draft
        child.save_draft
      end

      after { Draftsman.stash_drafted_changes = true }

      context 'with publication dependency' do
        it 'returns the parent' do
          expect(parent.draft.draft_reversion_dependencies).to eql [child.draft]
        end
      end

      context 'without publication dependency' do
        it 'returns the parent' do
          expect(child.draft.draft_reversion_dependencies).to eql []
        end
      end
    end
  end # #draft_reversion_dependencies
end
