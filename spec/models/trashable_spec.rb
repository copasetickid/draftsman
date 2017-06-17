require 'spec_helper'

# A Trashable has a simple call to `has_drafts` without any options specified. The model also contains a `deleted_at`
# attribute, which allows deletes to be drafts too.
describe Trashable do
  let(:trashable) { Trashable.new name: 'Bob' }

  describe '.draftable?' do
    it 'is draftable' do
      expect(subject.class.draftable?).to eql true
    end
  end

  # Not affected by this customization
  describe '#save_draft' do
  end

  describe '#draft_destruction' do
    context 'with `:create` draft' do
      before { trashable.save_draft }
      subject { trashable.draft_destruction; return trashable }

      it 'is persisted' do
        expect(subject).to be_persisted
      end

      it 'is not published' do
        expect(subject.published?).to eql false
      end

      it 'is a draft' do
        expect(subject.draft?).to eql true
      end

      it 'is trashed' do
        expect(subject.trashed?).to eql true
      end

      it 'does not have a `published_at` timestamp' do
        expect(subject.published_at).to be_nil
      end

      it 'has a `trashed_at` timestamp' do
        expect(subject.trashed_at).to be_present
      end

      it 'has a `draft_id`' do
        expect(subject.draft_id).to be_present
      end

      it 'has a `draft`' do
        expect(subject.draft).to be_present
      end

      it 'has a `destroy` draft' do
        expect(subject.draft.destroy?).to eql true
      end

      it 'retains its `name`' do
        expect(subject.name).to eql 'Bob'
      end

      it 'keeps the item' do
        expect { subject }.to_not change(Trashable, :count)
      end

      it 'keeps the associated draft' do
        expect { subject }.to_not change(Draftsman::Single::Draft.where(:id => trashable.draft_id), :count)
      end

      it 'retains its `name` in the draft' do
        expect(subject.draft.reify.name).to eql 'Bob'
      end
    end

    context 'with `:update` draft' do
      before do
        trashable.save!
        trashable.published_at = Time.now
        trashable.save!
        trashable.name = 'Sam'
        trashable.save_draft
      end

      subject { trashable.draft_destruction; return trashable.reload }

      it 'is persisted' do
        expect(subject).to be_persisted
      end

      it 'is published' do
        expect(subject.published?).to eql true
      end

      it 'is a draft' do
        expect(subject.draft?).to eql true
      end

      it 'is trashed' do
        expect(subject.trashed?).to eql true
      end

      it 'has a `published_at` timestamp' do
        expect(subject.published_at).to be_present
      end

      it 'has a `trashed_at` timestamp' do
        expect(subject.trashed_at).to be_present
      end

      it 'has a `draft_id`' do
        expect(subject.draft_id).to be_present
      end

      it 'has a `draft`' do
        expect(subject.draft).to be_present
      end

      it 'has a `destroy` draft' do
        expect(subject.draft.destroy?).to eql true
      end

      it 'retains its original `name`' do
        expect(subject.name).to eql 'Bob'
      end

      it 'keeps the item' do
        expect { subject }.to_not change(Trashable, :count)
      end

      it 'keeps the associated draft' do
        expect { subject }.to_not change(Draftsman::Single::Draft.where(:id => trashable.draft_id), :count)
      end

      it "retains the updated draft's name in the draft" do
        expect(subject.draft.reify.name).to eql 'Sam'
      end
    end

    context 'without draft' do
      before do
        trashable.save!
        trashable.update_attributes! :published_at => Time.now
      end

      subject { trashable.draft_destruction; return trashable.reload }

      it 'is persisted' do
        expect(subject).to be_persisted
      end

      it 'is published' do
        expect(subject.published?).to eql true
      end

      it 'is a draft' do
        expect(subject.draft?).to eql true
      end

      it 'is trashed' do
        expect(subject.trashed?).to eql true
      end

      it 'has a `published_at` timestamp' do
        expect(subject.published_at).to be_present
      end

      it 'has a `trashed_at` timestamp' do
        expect(subject.trashed_at).to be_present
      end

      it 'has a `draft_id`' do
        expect(subject.draft_id).to be_present
      end

      it 'has a `draft`' do
        expect(subject.draft).to be_present
      end

      it 'has a `destroy` draft' do
        expect(subject.draft.destroy?).to eql true
      end

      it 'retains its `name`' do
        expect(subject.name).to eql 'Bob'
      end

      it 'keeps the item' do
        expect { subject }.to_not change(Trashable, :count)
      end

      it 'creates a draft' do
        expect { subject }.to change(Draftsman::Single::Draft, :count).by(1)
      end
    end
  end

  describe 'scopes' do
    let!(:drafted_trashable)   { trashable.save_draft; return trashable }
    let!(:published_trashable) { Trashable.create(name: 'Jane', published_at: Time.now) }
    let!(:trashed_trashable)   { Trashable.create(name: 'Ralph') }

    # Not affected by this customization
    describe '.drafted' do
    end

    describe '.live' do
      before { trashed_trashable.draft_destruction }
      subject { Trashable.live }

      it 'returns 2 records' do
        expect(subject.count).to eql 2
      end

      it 'does not raise an exception' do
        expect { subject }.to_not raise_exception
      end

      it 'includes the drafted item' do
        expect(subject).to include drafted_trashable
      end

      it 'includes the published item' do
        expect(subject).to include published_trashable
      end

      it 'does not include the trashed item' do
        expect(subject).to_not include trashed_trashable
      end
    end

    # Not affected by this customization
    describe '.published' do
    end

    describe '.trashed' do
      before { trashed_trashable.draft_destruction }
      subject { Trashable.trashed }

      it 'returns 1 record' do
        expect(subject.count).to eql 1
      end

      it 'does not raise an exception' do
        expect { subject.load }.to_not raise_exception
      end

      it 'does not include the drafted item' do
        expect(subject).to_not include drafted_trashable
      end

      it 'does not include the published item' do
        expect(subject).to_not include published_trashable
      end

      it 'includes the trashed item' do
        expect(subject).to include trashed_trashable
      end
    end
  end
end
