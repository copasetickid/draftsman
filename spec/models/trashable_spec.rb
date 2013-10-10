require 'spec_helper'

# A Trashable has a simple call to `has_drafts` without any options specified. The model also contains a `deleted_at`
# attribute, which allows deletes to be drafts too.
describe Trashable do
  let(:trashable) { Trashable.new :name => 'Bob' }
  it { should be_draftable }

  # Not affected by this customization
  describe :draft_creation do
  end

  # Not affected by this customization
  describe :draft_update do
  end

  describe :draft_destroy do
    context 'with `:create` draft' do
      before { trashable.draft_creation }
      subject { trashable.draft_destroy; return trashable }
      it { should be_persisted }
      it { should_not be_published }
      it { should be_draft }
      it { should be_trashed}
      its(:published_at) { should be_nil }
      its(:trashed_at) { should be_present }
      its(:draft_id) { should be_present }
      its(:draft) { should be_present }
      its(:draft) { should be_destroy }
      its(:name) { should eql 'Bob' }

      it 'keeps the item' do
        expect { subject }.to_not change(Trashable, :count)
      end

      it 'keeps the associated draft' do
        expect { subject }.to_not change(Draftsman::Draft.where(:id => trashable.draft_id), :count)
      end

      its "draft's name should be 'Bob'" do
        subject.draft.reify.name.should eql 'Bob'
      end
    end

    context 'with `:update` draft' do
      before do
        trashable.save!
        trashable.published_at = Time.now
        trashable.save!
        trashable.name = 'Sam'
        trashable.draft_update
      end

      subject { trashable.draft_destroy; return trashable.reload }
      it { should be_persisted }
      it { should be_published }
      it { should be_draft }
      it { should be_trashed}
      its(:published_at) { should be_present }
      its(:trashed_at) { should be_present }
      its(:draft_id) { should be_present }
      its(:draft) { should be_present }
      its(:draft) { should be_destroy }
      its(:name) { should eql 'Bob' }

      it 'keeps the item' do
        expect { subject }.to_not change(Trashable, :count)
      end

      it 'keeps the associated draft' do
        expect { subject }.to_not change(Draftsman::Draft.where(:id => trashable.draft_id), :count)
      end

      its "draft's name should be 'Sam'" do
        subject.draft.reify.name.should eql 'Sam'
      end
    end

    context 'without draft' do
      before do
        trashable.save!
        trashable.update_attributes! :published_at => Time.now
      end

      subject { trashable.draft_destroy; return trashable.reload }
      it { should be_persisted }
      it { should be_published }
      it { should be_draft }
      it { should be_trashed }
      its(:published_at) { should be_present }
      its(:trashed_at) { should be_present }
      its(:draft_id) { should be_present }
      its(:draft) { should be_present }
      its(:draft) { should be_destroy }
      its(:name) { should eql 'Bob' }

      it 'keeps the item' do
        expect { subject }.to_not change(Trashable, :count)
      end

      it 'creates a draft' do
        expect { subject }.to change(Draftsman::Draft, :count).by(1)
      end
    end
  end

  describe 'scopes' do
    let!(:drafted_trashable)   { trashable.draft_creation; return trashable }
    let!(:published_trashable) { Trashable.create :name => 'Jane', :published_at => Time.now }
    let!(:trashed_trashable)   { Trashable.create :name => 'Ralph' }

    # Not affected by this customization
    describe :drafted do
    end

    describe :live do
      before { trashed_trashable.draft_destroy }
      subject { Trashable.live }
      its(:count) { should eql 2 }

      it 'does not raise an exception' do
        expect { subject }.to_not raise_exception
      end

      it 'includes the drafted item' do
        subject.should include drafted_trashable
      end

      it 'includes the published item' do
        subject.should include published_trashable
      end

      it 'does not include the trashed item' do
        subject.should_not include trashed_trashable
      end
    end

    # Not affected by this customization
    describe :published do
    end

    describe :trashed do
      before { trashed_trashable.draft_destroy }
      subject { Trashable.trashed }
      its(:count) { should eql 1 }

      it 'does not raise an exception' do
        expect { subject.load }.to_not raise_exception
      end

      it 'does not include the drafted item' do
        subject.should_not include drafted_trashable
      end

      it 'does not include the published item' do
        subject.should_not include published_trashable
      end

      it 'includes the trashed item' do
        subject.should include trashed_trashable
      end
    end
  end
end
