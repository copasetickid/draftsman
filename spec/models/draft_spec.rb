require 'spec_helper'

describe Draftsman::Draft do
  describe 'class methods' do
    subject { Draftsman::Draft }

    it 'does not have a JSON object column' do
      expect(subject.object_col_is_json?).to eql false
    end

    it 'does not have a JSON object_changes column' do
      expect(subject.object_changes_col_is_json?).to eql false
    end

    it 'does not have a JSON previous_draft column' do
      expect(subject.previous_draft_col_is_json?).to eql false
    end
  end

  describe 'instance methods' do
    let(:trashable) { Trashable.new :name => 'Bob' }
    subject { trashable.draft }

    describe 'event, create?, update?, destroy?, object, changeset' do
      context 'with `create` draft' do
        before { trashable.draft_creation }

        it 'is a `create` event' do
          expect(subject.event).to eql 'create'
        end

        it 'identifies as a `create` event' do
          expect(subject.create?).to eql true
        end

        it 'does not identify as an `update` event' do
          expect(subject.update?).to eql false
        end

        it 'does not identify as a `destroy` event' do
          expect(subject.destroy?).to eql false
        end

        it 'has an object' do
          expect(subject.object).to be_present
        end

        it 'has an `id` in the `changeset`' do
          expect(subject.changeset).to include :id
        end

        it 'has a `name` in the `changeset`' do
          expect(subject.changeset).to include :name
        end

        it 'does not have a `title` in the `changeset`' do
          expect(subject.changeset).to_not include :title
        end

        it 'has `created_at` in the `changeset`' do
          expect(subject.changeset).to include :created_at
        end

        it 'has `updated_at` in the `changeset`' do
          expect(subject.changeset).to include :updated_at
        end

        it 'does not have a `previous_draft`' do
          expect(subject.previous_draft).to be_nil
        end

        context 'updated create' do
          before do
            trashable.name = 'Sam'
            trashable.draft_update
          end

          it 'identifies as a `create` event' do
            expect(subject.create?).to eql true
          end

          it 'does not identify as an `update` event' do
            expect(subject.update?).to eql false
          end

          it 'does not identify as a `destroy` event' do
            expect(subject.destroy?).to eql false
          end

          it 'is a `create` event' do
            expect(subject.event).to eql 'create'
          end

          it 'has an `object`' do
            expect(subject.object).to be_present
          end

          it 'has an `id` in the `changeset`' do
            expect(subject.changeset).to include :id
          end

          it 'has a `name` in the `changeset`' do
            expect(subject.changeset).to include :name
          end

          it 'does not have a `title` in the `changeset`' do
            expect(subject.changeset).to_not include :title
          end

          it 'has `created_at` in the `changeset`' do
            expect(subject.changeset).to include :created_at
          end

          it 'has `updated_at` in the `changeset`' do
            expect(subject.changeset).to include :updated_at
          end

          it 'does not have a `previous_draft`' do
            expect(subject.previous_draft).to be_nil
          end
        end
      end

      context 'with `update` draft' do
        before do
          trashable.save!
          trashable.name = 'Sam'
          trashable.title = 'My Title'
          trashable.draft_update
        end

        it 'does not identify as a `create` event' do
          expect(subject.create?).to eql false
        end

        it 'identifies as an `update event' do
          expect(subject.update?).to eql true
        end

        it 'does not identify as a `destroy` event' do
          expect(subject.destroy?).to eql false
        end

        it 'has an `update` event' do
          expect(subject.event).to eql 'update'
        end

        it 'has an `object`' do
          expect(subject.object).to be_present
        end

        it 'does not have an `id` in the `changeset`' do
          expect(subject.changeset).to_not include :id
        end

        it 'has a `name` in the `changeset`' do
          expect(subject.changeset).to include :name
        end

        it 'has a `title` in the `changeset`' do
          expect(subject.changeset).to include :title
        end

        it 'does not have `created_at` in the `changeset`' do
          expect(subject.changeset).to_not include :created_at
        end

        it 'does not have `updated_at` in the `changeset`' do
          expect(subject.changeset).to_not include :updated_at
        end

        it 'does not have a `previous_draft`' do
          expect(subject.previous_draft).to be_nil
        end

        context 'updating the update' do
          before do
            trashable.title = nil
            trashable.draft_update
          end

          it 'does not identify as a `create` event' do
            expect(subject.create?).to eql false
          end

          it 'identifies as an `update` event' do
            expect(subject.update?).to eql true
          end

          it 'does not identify as a `destroy` event' do
            expect(subject.destroy?).to eql false
          end

          it 'has an `update` event' do
            expect(subject.event).to eql 'update'
          end

          it 'has an `object`' do
            expect(subject.object).to be_present
          end

          it 'does not have an `id` in the `changeset`' do
            expect(subject.changeset).to_not include :id
          end

          it 'has a `name` in the `changeset`' do
            expect(subject.changeset).to include :name
          end

          it 'does not have a `title` in the `changeset`' do
            expect(subject.changeset).to_not include :title
          end

          it 'does not have `created_at` in the `changeset`' do
            expect(subject.changeset).to_not include :created_at
          end

          it 'does not have `updated_at` in the `changeset`' do
            expect(subject.changeset).to_not include :updated_at
          end

          it 'does not have a `previous_draft`' do
            expect(subject.previous_draft).to be_nil
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
            expect(subject.create?).to eql false
          end

          it 'does not identify as an `update` event' do
            expect(subject.update?).to eql false
          end

          it 'identifies as a `destroy` event' do
            expect(subject.destroy?).to eql true
          end

          it 'is not destroyed' do
            expect(subject.destroyed?).to eql false
          end

          it 'is a `destroy` event' do
            expect(subject.event).to eql 'destroy'
          end

          it 'has an `object`' do
            expect(subject.object).to be_present
          end

          it 'has an empty `changeset`' do
            expect(subject.changeset).to eql Hash.new
          end

          it 'does not have a `previous_draft`' do
            expect(subject.previous_draft).to be_nil
          end
        end

        context 'with previous `create` draft' do
          before do
            trashable.draft_creation
            trashable.draft_destruction
          end

          it 'does not identify as a `create` event' do
            expect(subject.create?).to eql false
          end

          it 'does not identify as an `update` event' do
            expect(subject.update?).to eql false
          end

          it 'identifies as a `destroy` event' do
            expect(subject.destroy?).to eql true
          end

          it 'is not destroyed' do
            expect(subject.destroyed?).to eql false
          end

          it 'is a `destroy` event' do
            expect(subject.event).to eql 'destroy'
          end

          it 'has an `object`' do
            expect(subject.object).to be_present
          end

          it 'has an `id` in the `changeset`' do
            expect(subject.changeset).to include :id
          end

          it 'has a `name` in the `changeset`' do
            expect(subject.changeset).to include :name
          end

          it 'does not have a `title` in the `changeset`' do
            expect(subject.changeset).to_not include :title
          end

          it 'has `created_at` in the `changeset`' do
            expect(subject.changeset).to include :created_at
          end

          it 'has `updated_at` in the `changeset`' do
            expect(subject.changeset).to include :updated_at
          end

          it 'has a `previous_draft`' do
            expect(subject.previous_draft).to be_present
          end
        end
      end
    end

    describe 'publish!' do
      context 'with `create` draft' do
        before { trashable.draft_creation }
        subject { trashable.draft.publish!; return trashable.reload }

        it 'does not raise an exception' do
          expect { subject }.to_not raise_exception
        end

        it 'publishes the item' do
          expect(subject.published?).to eql true
        end

        it 'is not trashed' do
          expect(subject.trashed?).to eql false
        end

        it 'is no longer a draft' do
          expect(subject.draft?).to eql false
        end

        it 'should have a `published_at` timestamp' do
          expect(subject.published_at).to be_present
        end

        it 'does not have a `draft_id`' do
          expect(subject.draft_id).to be_nil
        end

        it 'does not have a draft' do
          expect(subject.draft).to be_nil
        end

        it 'does not have a `trashed_at` timestamp' do
          expect(subject.trashed_at).to be_nil
        end

        it 'deletes the draft record' do
          expect { subject }.to change(Draftsman::Draft, :count).by(-1)
        end
      end

      context 'with `update` draft' do
        before do
          trashable.save!
          trashable.name = 'Sam'
          trashable.draft_update
        end

        subject { trashable.draft.publish!; return trashable.reload }

        it 'does not raise an exception' do
          expect { subject }.to_not raise_exception
        end

        it 'publishes the item' do
          expect(subject.published?).to eql true
        end

        it 'is no longer a draft' do
          expect(subject.draft?).to eql false
        end

        it 'is not trashed' do
          expect(subject.trashed?).to eql false
        end

        it 'has an updated `name`' do
          expect(subject.name).to eql 'Sam'
        end

        it 'has a `published_at` timestamp' do
          expect(subject.published_at).to be_present
        end

        it 'does not have a `draft_id`' do
          expect(subject.draft_id).to be_nil
        end

        it 'does not have a `draft`' do
          expect(subject.draft).to be_nil
        end

        it 'does not have a `trashed_at` timestamp' do
          expect(subject.trashed_at).to be_nil
        end

        it 'destroys the draft' do
          expect { subject }.to change(Draftsman::Draft, :count).by(-1)
        end

        it 'does not delete the associated item' do
          expect { subject }.to_not change(Trashable, :count)
        end
      end

      context 'with `destroy` draft' do
        context 'without previous draft' do
          before do
            trashable.save!
            trashable.draft_destruction
          end

          subject { trashable.draft.publish! }

          it 'destroys the draft' do
            expect { subject }.to change(Draftsman::Draft, :count).by(-1)
          end

          it 'deletes the associated item' do
            expect { subject }.to change(Trashable, :count).by(-1)
          end
        end

        context 'with previous `create` draft' do
          before do
            trashable.draft_creation
            trashable.draft_destruction
          end

          subject { trashable.draft.publish! }

          it 'destroys the draft' do
            expect { subject }.to change(Draftsman::Draft, :count).by(-1)
          end

          it 'deletes the associated item' do
            expect { subject }.to change(Trashable, :count).by(-1)
          end
        end
      end
    end

    describe 'revert!' do
      context 'with `create` draft' do
        before { trashable.draft_creation }
        subject { trashable.draft.revert! }

        it 'does not raise an exception' do
          expect { subject }.to_not raise_exception
        end

        it 'destroys the draft' do
          expect { subject }.to change(Draftsman::Draft, :count).by(-1)
        end

        it 'destroys associated item' do
          expect { subject }.to change(Trashable, :count).by(-1)
        end
      end

      context 'with `update` draft' do
        before do
          trashable.save!
          trashable.name = 'Sam'
          trashable.draft_update
        end

        subject { trashable.draft.revert!; return trashable.reload }

        it 'does not raise an exception' do
          expect { subject }.to_not raise_exception
        end

        it 'is no longer a draft' do
          expect(subject.draft?).to eql false
        end

        it 'reverts its `name`' do
          expect(subject.name).to eql 'Bob'
        end

        it 'does not have a `draft_id`' do
          expect(subject.draft_id).to be_nil
        end

        it 'does not have a `draft`' do
          expect(subject.draft).to be_nil
        end

        it 'destroys the draft record' do
          expect { subject }.to change(Draftsman::Draft, :count).by(-1)
        end

        it 'does not destroy the associated item' do
          expect { subject }.to_not change(Trashable, :count)
        end
      end

      context 'with `destroy` draft' do
        context 'without previous draft' do
          before do
            trashable.save!
            trashable.draft_destruction
          end

          subject { trashable.draft.revert!; return trashable.reload }

          it 'does not raise an exception' do
            expect { subject }.to_not raise_exception
          end

          it 'is not trashed' do
            expect(subject.trashed?).to eql false
          end

          it 'is no longer a draft' do
            expect(subject.draft?).to eql false
          end

          it 'does not have a `draft_id`' do
            expect(subject.draft_id).to be_nil
          end

          it 'does not have a `draft`' do
            expect(subject.draft).to be_nil
          end

          it 'does not have a `trashed_at` timestamp' do
            expect(subject.trashed_at).to be_nil
          end

          it 'destroys the draft record' do
            expect { subject }.to change(Draftsman::Draft, :count).by(-1)
          end

          it 'does not destroy the associated item' do
            expect { subject }.to_not change(Trashable, :count)
          end
        end

        context 'with previous `create` draft' do
          before do
            trashable.draft_creation
            trashable.draft_destruction
          end

          subject { trashable.draft.revert!; return trashable.reload }

          it 'does not raise an exception' do
            expect { subject }.to_not raise_exception
          end

          it 'is not trashed' do
            expect(subject.trashed?).to eql false
          end

          it 'is a draft' do
            expect(subject.draft?).to eql true
          end

          it 'has a `draft_id`' do
            expect(subject.draft_id).to be_present
          end

          it 'has a `draft`' do
            expect(subject.draft).to be_present
          end

          it 'does not have a `trashed_at` timestamp' do
            expect(subject.trashed_at).to be_nil
          end

          it 'destroys the `destroy` draft record' do
            expect { subject }.to change(Draftsman::Draft.where(:event => 'destroy'), :count).by(-1)
          end

          it 'reifies the previous `create` draft record' do
            expect { subject }.to change(Draftsman::Draft.where(:event => 'create'), :count).by(1)
          end

          it 'does not destroy the associated item' do
            expect { subject }.to_not change(Trashable, :count)
          end

          it "no longer has a `previous_draft`" do
            expect(subject.draft.previous_draft).to be_nil
          end
        end
      end
    end

    describe 'reify' do
      subject { trashable.draft.reify }

      context 'with `create` draft' do
        before { trashable.draft_creation }

        it "has a `title` that matches the item's" do
          expect(subject.title).to eql trashable.title
        end

        context 'updated create' do
          before do
            trashable.name = 'Sam'
            trashable.draft_update
          end

          it 'has an updated `name`' do
            expect(subject.name).to eql 'Sam'
          end

          it 'has no `title`' do
            expect(subject.title).to be_nil
          end
        end
      end

      context 'with `update` draft' do
        before do
          trashable.save!
          trashable.name = 'Sam'
          trashable.title = 'My Title'
          trashable.draft_update
        end

        it 'has the updated `name`' do
          expect(subject.name).to eql 'Sam'
        end

        it 'has the updated `title`' do
          expect(subject.title).to eql 'My Title'
        end

        context 'updating the update' do
          before do
            trashable.title = nil
            trashable.draft_update
          end

          it 'has the same `name`' do
            expect(subject.name).to eql 'Sam'
          end

          it 'has the updated `title`' do
            expect(subject.title).to be_nil
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
            expect(subject.name).to eql 'Bob'
          end

          it 'records the `title`' do
            expect(subject.title).to be_nil
          end
        end

        context 'with previous `create` draft' do
          before do
            trashable.draft_creation
            trashable.draft_destruction
          end

          it 'records the `name`' do
            expect(subject.name).to eql 'Bob'
          end

          it 'records the `title`' do
            expect(subject.title).to be_nil
          end
        end

        context 'with previous `update` draft' do
          before do
            trashable.save!
            trashable.name = 'Sam'
            trashable.title = 'My Title'
            trashable.draft_update
            # Typically, 2 draft operations won't happen in the same request, so reload before draft-destroying.
            trashable.reload.draft_destruction
          end

          it 'records the updated `name`' do
            expect(subject.name).to eql 'Sam'
          end

          it 'records the updated `title`' do
            expect(subject.title).to eql 'My Title'
          end
        end
      end
    end
  end
end
