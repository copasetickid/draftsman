require 'spec_helper'

describe Draftsman::Draft do
  let(:trashable) { Trashable.new :name => 'Bob' }
  subject { trashable.draft }

  describe :event, :create?, :update?, :destroy?, :object, :changeset do
    context 'with `create` draft' do
      before { trashable.draft_creation }
      its(:event) { should eql 'create' }
      its(:create?) { should be_true }
      its(:update?) { should be_false }
      its(:destroy?) { should be_false }
      its(:object) { should be_present }
      its(:changeset) { should include :id }
      its(:changeset) { should include :name }
      its(:changeset) { should_not include :title }
      its(:changeset) { should include :created_at }
      its(:changeset) { should include :updated_at }
      its(:previous_draft) { should be_nil }

      context 'updated create' do
        before do
          trashable.name = 'Sam'
          trashable.draft_update
        end

        it { should be_create }
        it { should_not be_update }
        it { should_not be_destroy }
        its(:event) { should eql 'create' }
        its(:object) { should be_present }
        its(:changeset) { should include :id }
        its(:changeset) { should include :name }
        its(:changeset) { should_not include :title }
        its(:changeset) { should include :created_at }
        its(:changeset) { should include :updated_at }
        its(:previous_draft) { should be_nil }
      end
    end

    context 'with `update` draft' do
      before do
        trashable.save!
        trashable.name = 'Sam'
        trashable.title = 'My Title'
        trashable.draft_update
      end

      it { should_not be_create }
      it { should be_update }
      it { should_not be_destroy }
      its(:event) { should eql 'update' }
      its(:object) { should be_present }
      its(:changeset) { should_not include :id }
      its(:changeset) { should include :name }
      its(:changeset) { should include :title }
      its(:changeset) { should_not include :created_at }
      its(:changeset) { should_not include :updated_at }
      its(:previous_draft) { should be_nil }

      context 'updating the update' do
        before do
          trashable.title = nil
          trashable.draft_update
        end

        it { should_not be_create }
        it { should be_update }
        it { should_not be_destroy }
        its(:event) { should eql 'update' }
        its(:object) { should be_present }
        its(:changeset) { should_not include :id }
        its(:changeset) { should include :name }
        its(:changeset) { should_not include :title }
        its(:changeset) { should_not include :created_at }
        its(:changeset) { should_not include :updated_at }
        its(:previous_draft) { should be_nil }
      end
    end

    context 'with `destroy` draft' do
      context 'without previous draft' do
        before do
          trashable.save!
          trashable.draft_destroy
        end

        it { should_not be_create }
        it { should_not be_update }
        it { should be_destroy }
        it { should_not be_destroyed }
        its(:event) { should eql 'destroy' }
        its(:object) { should be_present }
        its(:changeset) { should eql Hash.new }
        its(:previous_draft) { should be_nil }
      end

      context 'with previous `create` draft' do
        before do
          trashable.draft_creation
          trashable.draft_destroy
        end

        it { should_not be_create }
        it { should_not be_update }
        it { should be_destroy }
        it { should_not be_destroyed }
        its(:event) { should eql 'destroy' }
        its(:object) { should be_present }
        its(:changeset) { should include :id }
        its(:changeset) { should include :name }
        its(:changeset) { should_not include :title }
        its(:changeset) { should include :created_at }
        its(:changeset) { should include :updated_at }
        its(:previous_draft) { should be_present }
      end
    end
  end

  describe :publish! do
    context 'with `create` draft' do
      before { trashable.draft_creation }
      subject { trashable.draft.publish!; return trashable.reload }
      it { expect { subject }.to_not raise_exception }
      it { should be_published }
      it { should_not be_trashed }
      it { should_not be_draft }
      its(:published_at) { should be_present }
      its(:draft_id) { should be_nil }
      its(:draft) { should be_nil }
      its(:trashed_at) { should be_nil }

      it 'deletes the draft' do
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
      it { expect { subject }.to_not raise_exception }
      it { should be_published }
      it { should_not be_draft }
      it { should_not be_trashed }
      its(:name) { should eql 'Sam' }
      its(:published_at) { should be_present }
      its(:draft_id) { should be_nil }
      its(:draft) { should be_nil }
      its(:trashed_at) { should be_nil }

      it 'deletes the draft' do
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
          trashable.draft_destroy
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
          trashable.draft_destroy
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

  describe :revert! do
    context 'with `create` draft' do
      before { trashable.draft_creation }
      subject { trashable.draft.revert! }
      it { expect { subject }.to_not raise_exception }

      it 'deletes the draft' do
        expect { subject }.to change(Draftsman::Draft, :count).by(-1)
      end

      it 'deletes associated item' do
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
      it { expect { subject }.to_not raise_exception }
      it { should_not be_draft }
      its(:name) { should eql 'Bob' }
      its(:draft_id) { should be_nil }
      its(:draft) { should be_nil }

      it 'deletes the draft' do
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
          trashable.draft_destroy
        end

        subject { trashable.draft.revert!; return trashable.reload }
        it { expect { subject }.to_not raise_exception }
        it { should_not be_trashed }
        it { should_not be_draft }
        its(:draft_id) { should be_nil }
        its(:draft) { should be_nil }
        its(:trashed_at) { should be_nil }

        it 'deletes the draft' do
          expect { subject }.to change(Draftsman::Draft, :count).by(-1)
        end

        it 'does not delete the associated item' do
          expect { subject }.to_not change(Trashable, :count)
        end
      end

      context 'with previous `create` draft' do
        before do
          trashable.draft_creation
          trashable.draft_destroy
        end

        subject { trashable.draft.revert!; return trashable.reload }
        it { expect { subject }.to_not raise_exception }
        it { should_not be_trashed }
        it { should be_draft }
        its(:draft_id) { should be_present }
        its(:draft) { should be_present }
        its(:trashed_at) { should be_nil }

        it 'deletes the `destroy` draft' do
          expect { subject }.to change(Draftsman::Draft.where(:event => 'destroy'), :count).by(-1)
        end

        it 'reifies the previous `create` draft' do
          expect { subject }.to change(Draftsman::Draft.where(:event => 'create'), :count).by(1)
        end

        it 'does not delete the associated item' do
          expect { subject }.to_not change(Trashable, :count)
        end

        its "draft's previous draft should be nil" do
          subject.draft.previous_draft.should be_nil
        end
      end
    end
  end

  describe :reify do
    subject { trashable.draft.reify }

    context 'with `create` draft' do
      before { trashable.draft_creation }
      its(:title) { should eql trashable.title }

      context 'updated create' do
        before do
          trashable.name = 'Sam'
          trashable.draft_update
        end

        its(:name) { should eql 'Sam' }
        its(:title) { should be_nil }
      end
    end

    context 'with `update` draft' do
      before do
        trashable.save!
        trashable.name = 'Sam'
        trashable.title = 'My Title'
        trashable.draft_update
      end

      its(:name) { should eql 'Sam' }
      its(:title) { should eql 'My Title' }

      context 'updating the update' do
        before do
          trashable.title = nil
          trashable.draft_update
        end

        its(:name) { should eql 'Sam' }
        its(:title) { should be_nil }
      end
    end

    context 'with `destroy` draft' do
      context 'without previous draft' do
        before do
          trashable.save!
          trashable.draft_destroy
        end

        its(:name) { should eql 'Bob' }
        its(:title) { should be_nil }
      end

      context 'with previous `create` draft' do
        before do
          trashable.draft_creation
          trashable.draft_destroy
        end

        its(:name) { should eql 'Bob' }
        its(:title) { should be_nil }
      end

      context 'with previous `update` draft' do
        before do
          trashable.save!
          trashable.name = 'Sam'
          trashable.title = 'My Title'
          trashable.draft_update
          # Typically, 2 draft operations won't happen in the same request, so reload before draft-destroying.
          trashable.reload.draft_destroy
        end

        its(:name) { should eql 'Sam' }
        its(:title) { should eql 'My Title' }
      end
    end
  end
end
