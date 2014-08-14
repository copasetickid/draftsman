require 'spec_helper'

describe Skipper do
  let(:skipper) { Skipper.new :name => 'Bob', :skip_me => 'Skipped 1' }
  it { should be_draftable }

  describe :draft_creation do
    subject do
      skipper.draft_creation
      skipper.reload
    end

    it { should be_persisted }
    it { should be_draft }
    its(:draft_id) { should be_present }
    its(:draft) { should be_present }
    its(:draft) { should be_create }
    its(:name) { should eql 'Bob' }
    its(:skip_me) { should eql 'Skipped 1' }
  end

  describe :draft_update do
    subject do
      skipper.draft_update
      skipper.reload
    end

    context 'without existing draft' do
      before do
        skipper.save!
        skipper.name = 'Sam'
        skipper.skip_me = 'Skipped 2'
      end

      it { should be_persisted }
      it { should be_draft }
      its(:draft_id) { should be_present }
      its(:draft) { should be_present }
      its(:draft) { should be_update }
      its(:name) { should eql 'Bob' }
      its(:skip_me) { should eql 'Skipped 2' }

      it 'creates a new draft' do
        expect { subject }.to change(Draftsman::Draft, :count).by(1)
      end
    end

    describe 'changing back to initial state' do
      before do
        skipper.published_at = Time.now
        skipper.save!
        skipper.name = 'Sam'
        skipper.draft_update
        skipper.reload
        skipper.name = 'Bob'
        skipper.skip_me = 'Skipped 2'
      end

      it { should_not be_draft }
      its(:draft_id) { should be_nil }
      its(:draft) { should be_nil }
      its(:name) { should eql 'Bob' }
      its(:skip_me) { should eql 'Skipped 2' }

      it 'destroys the draft' do
        expect { subject }.to change(Draftsman::Draft.where(:id => skipper.draft_id), :count).by(-1)
      end
    end

    context 'with existing `create` draft' do
      before { skipper.draft_creation }

      context 'with changes' do
        before do
          skipper.name = 'Sam'
          skipper.skip_me = 'Skipped 2'
        end

        it { should be_persisted }
        it { should be_draft }
        its(:draft_id) { should be_present }
        its(:draft) { should be_present }
        its(:draft) { should be_create }
        its(:name) { should eql 'Sam' }
        its(:skip_me) { should eql 'Skipped 2' }

        it 'updates the existing draft' do
          expect { subject }.to_not change(Draftsman::Draft.where(:id => skipper.draft_id), :count)
        end

        its "draft's `name` is updated" do
          subject.draft.reify.name.should eql 'Sam'
        end
      end

      context 'with no changes' do
        it { should be_persisted }
        it { should be_draft }
        its(:draft_id) { should be_present }
        its(:draft) { should be_present }
        its(:draft) { should be_create }
        its(:name) { should eql 'Bob' }
        its(:skip_me) { should eql 'Skipped 1' }

        it "doesn't change the number of drafts" do
          expect { subject }.to_not change(Draftsman::Draft.where(:id => skipper.draft_id), :count)
        end
      end
    end

    context 'with existing `update` draft' do
      before do
        skipper.save!
        skipper.name = 'Sam'
        skipper.skip_me = 'Skipped 2'
        skipper.draft_update
        skipper.reload
        skipper.attributes = skipper.draft.reify.attributes
      end

      context 'with changes' do
        before { skipper.name = 'Steve' }
        it { should be_persisted }
        it { should be_draft }
        its(:draft_id) { should be_present }
        its(:draft) { should be_present }
        its(:draft) { should be_update }
        its(:name) { should eql 'Bob' }
        its(:skip_me) { should eql 'Skipped 2' }

        it 'updates the existing draft' do
          expect { subject }.to_not change(Draftsman::Draft.where(:id => skipper.draft_id), :count)
        end

        its "draft's `name` is updated" do
          subject.draft.reify.name.should eql 'Steve'
        end
      end

      context 'with no changes' do
        it { should be_persisted }
        it { should be_draft }
        its(:draft_id) { should be_present }
        its(:draft) { should be_present }
        its(:draft) { should be_update }
        its(:name) { should eql 'Bob' }
        its(:skip_me) { should eql 'Skipped 2' }

        it "doesn't change the number of drafts" do
          expect { subject }.to_not change(Draftsman::Draft.where(:id => skipper.draft_id), :count)
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

  # Not applicable to this customization
  describe 'scopes' do
  end
end
