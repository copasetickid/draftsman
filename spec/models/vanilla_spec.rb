require 'spec_helper'

# A Vanilla has a simple call to `has_drafts` without any options specified.
describe Vanilla do
  let(:vanilla) { Vanilla.new :name => 'Bob' }
  it { should be_draftable }

  describe :draft_creation do
    subject do
      vanilla.draft_creation
      vanilla.reload
    end

    it { should be_persisted }
    it { should be_draft }
    its(:draft_id) { should be_present }
    its(:draft) { should be_present }
    its(:draft) { should be_create }
    its(:name) { should eql 'Bob' }
  end

  describe :draft_update do
    subject do
      vanilla.draft_update
      vanilla.reload
    end

    context 'without existing draft' do
      before do
        vanilla.save!
        vanilla.name = 'Sam'
      end

      it { should be_persisted }
      it { should be_draft }
      its(:draft_id) { should be_present }
      its(:draft) { should be_present }
      its(:draft) { should be_update }
      its(:name) { should eql 'Bob' }

      it 'creates a new draft' do
        expect { subject }.to change(Draftsman::Draft, :count).by(1)
      end
    end

    describe 'changing back to initial state' do
      before do
        vanilla.published_at = Time.now
        vanilla.save!
        vanilla.name = 'Sam'
        vanilla.draft_update
        vanilla.reload
        vanilla.name = 'Bob'
      end

      it { should_not be_draft }
      its(:name) { should eql 'Bob' }
      its(:draft_id) { should be_nil }
      its(:draft) { should be_nil }

      it 'destroys the draft' do
        expect { subject }.to change(Draftsman::Draft.where(:id => vanilla.draft_id), :count).by(-1)
      end
    end

    context 'with existing `create` draft' do
      before { vanilla.draft_creation }

      context 'with changes' do
        before { vanilla.name = 'Sam' }
        it { should be_persisted }
        it { should be_draft }
        its(:draft_id) { should be_present }
        its(:draft) { should be_present }
        its(:name) { should eql 'Sam' }

        it 'updates the existing draft' do
          expect { subject }.to_not change(Draftsman::Draft.where(:id => vanilla.draft_id), :count)
        end

        its "draft's `name` is updated" do
          subject.draft.reify.name.should eql 'Sam'
        end

        it 'has a `create` draft' do
          subject.draft.should be_create
        end
      end

      context 'with no changes' do
        it { should be_persisted }
        it { should be_draft }
        its(:draft_id) { should be_present }
        its(:draft) { should be_present }
        its(:draft) { should be_create }
        its(:name) { should eql 'Bob' }

        it "doesn't change the number of drafts" do
          expect { subject }.to_not change(Draftsman::Draft.where(:id => vanilla.draft_id), :count)
        end
      end
    end

    context 'with existing `update` draft' do
      before do
        vanilla.save!
        vanilla.name = 'Sam'
        vanilla.draft_update
      end

      context 'with changes' do
        before { vanilla.name = 'Steve' }
        it { should be_persisted }
        it { should be_draft }
        its(:draft_id) { should be_present }
        its(:draft) { should be_present }
        its(:name) { should eql 'Bob' }

        it 'updates the existing draft' do
          expect { subject }.to_not change(Draftsman::Draft.where(:id => vanilla.draft_id), :count)
        end

        its "draft's `name` is updated" do
          subject.draft.reify.name.should eql 'Steve'
        end

        it 'has a `create` draft' do
          subject.draft.update?.should be_true
        end
      end

      context 'with no changes' do
        it { should be_persisted }
        it { should be_draft }
        its(:draft_id) { should be_present }
        its(:draft) { should be_present }
        its(:draft) { should be_update }
        its(:name) { should eql 'Bob' }

        it "doesn't change the number of drafts" do
          expect { subject }.to_not change(Draftsman::Draft.where(:id => vanilla.draft_id), :count)
        end

        its "draft's `name` is not updated" do
          subject.draft.reify.name.should eql 'Sam'
        end
      end
    end
  end

  # Not applicable to this customization
  describe :draft_destroy do
  end

  describe 'scopes' do
    let!(:drafted_vanilla)   { vanilla.draft_creation; return vanilla }
    let!(:published_vanilla) { Vanilla.create :name => 'Jane', :published_at => Time.now }

    describe :drafted do
      subject { Vanilla.drafted }
      its(:count) { should eql 1 }

      it 'includes the unpublished item' do
        subject.should include drafted_vanilla
      end

      it 'does not include the published item' do
        subject.should_not include published_vanilla
      end
    end

    describe :live do
      subject { Vanilla.live }

      it 'raises an exception' do
        expect { subject.load }.to raise_exception
      end
    end

    describe :published do
      subject { Vanilla.published }
      its(:count) { should eql 1 }

      it 'does not include the unpublished item' do
        subject.should_not include drafted_vanilla
      end

      it 'includes the published item' do
        subject.should include published_vanilla
      end
    end

    describe :trashed do
      subject { Vanilla.trashed }

      it 'raises an exception' do
        expect { subject.load }.to raise_exception
      end
    end
  end
end
