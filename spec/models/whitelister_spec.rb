require 'spec_helper'

describe Whitelister do
  let(:whitelister) { Whitelister.new :name => 'Bob' }
  it { should be_draftable }

  # Not affected by this customization
  describe :draft_creation do
  end

  describe :draft_update do
    subject do
      whitelister.draft_update
      whitelister.reload
    end

    context 'with whitelisted change' do
      context 'without draft' do
        before do
          whitelister.save!
          whitelister.attributes = { :name => 'Sam', :ignored => 'Meh.' }
        end

        it { should be_persisted }
        it { should be_draft }
        its(:draft_id) { should be_present }
        its(:draft) { should be_present }
        its(:draft) { should be_update }
        its(:name) { should eql 'Bob' }
        its(:ignored) { should eql 'Meh.' }

        it 'creates a new draft' do
          expect { subject }.to change(Draftsman::Draft, :count).by(1)
        end

        it 'has an `update` draft' do
          subject.draft.update?.should be_true
        end

        its "draft's name should be `Sam`" do
          subject.draft.reify.name.should eql 'Sam'
        end

        context 'changing back to initial state' do
          before do
            whitelister.draft_update
            whitelister.attributes = { :name => 'Bob', :ignored => 'Huzzah!' }
          end
          
          it { should_not be_draft }
          its(:name) { should eql 'Bob' }
          its(:ignored) { should eql 'Huzzah!' }
          its(:draft_id) { should be_nil }
          its(:draft) { should be_nil }

          it 'destroys the draft' do
            expect { subject }.to change(Draftsman::Draft.where(:id => whitelister.draft_id), :count).by(-1)
          end
        end
      end

      context 'with existing `create` draft' do
        before { whitelister.draft_creation }

        context 'with changes' do
          before { whitelister.attributes = { :name => 'Sam', :ignored => 'Meh.' } }
          it { should be_persisted }
          it { should be_draft }
          its(:draft_id) { should be_present }
          its(:draft) { should be_present }
          its(:draft) { should be_create }
          its(:name) { should eql 'Sam' }

          it 'updates the existing draft' do
            expect { subject }.to_not change(Draftsman::Draft.where(:id => whitelister.draft_id), :count)
          end

          its "draft's `name` is updated" do
            subject.draft.reify.name.should eql 'Sam'
          end

          its "draft's `ignored` is updated" do
            subject.draft.reify.ignored.should eql 'Meh.'
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
            expect { subject }.to_not change(Draftsman::Draft.where(:id => whitelister.draft_id), :count)
          end
        end
      end

      context 'with existing `update` draft' do
        before do
          whitelister.save!
          whitelister.attributes = { :name => 'Sam', :ignored => 'Meh.' }
        end
        
        context 'with changes' do
          before { whitelister.attributes = { :name => 'Steve', :ignored => 'Huzzah!' } }
          it { should be_persisted }
          it { should be_draft }
          its(:draft_id) { should be_present }
          its(:draft) { should be_present }
          its(:draft) { should be_update }
          its(:name) { should eql 'Bob' }
          its(:ignored) { should eql 'Huzzah!' }

          it 'updates the existing draft' do
            expect { subject }.to_not change(Draftsman::Draft.where(:id => whitelister.draft_id), :count)
          end

          its "draft's `name` is updated" do
            subject.draft.reify.name.should eql 'Steve'
          end

          its "draft's `ignored` is 'Huzzah!'" do
            subject.draft.reify.ignored.should eql 'Huzzah!'
          end
        end

        context 'with no changes' do
          it { should be_persisted }
          it { should be_draft }
          its(:draft_id) { should be_present }
          its(:draft) { should be_present }
          its(:name) { should eql 'Bob' }

          it "doesn't change the number of drafts" do
            expect { subject }.to_not change(Draftsman::Draft.where(:id => whitelister.draft_id), :count)
          end

          its "draft's `name` is not updated" do
            subject.draft.reify.name.should eql 'Sam'
          end

          it 'still has an `update` draft' do
            subject.draft.update?.should be_true
          end
        end
      end
    end

    context 'without whitelisted change' do
      context 'without existing draft' do
        before do
          whitelister.save!
          whitelister.ignored = 'Huzzah!'
        end

        it { should be_persisted }
        it { should_not be_draft }
        its(:draft_id) { should be_nil }
        its(:draft) { should be_nil }
        its(:name) { should eql 'Bob' }
        its(:ignored) { should eql 'Huzzah!' }

        it 'does not create a draft' do
          expect { subject }.to_not change(Draftsman::Draft, :count)
        end

        # Not affected by this customization
        context 'changing back to initial state' do
        end
      end

      context 'with existing `create` draft' do
        before do
          whitelister.draft_creation
          whitelister.ignored = 'Huzzah!'
        end

        it { should be_persisted }
        it { should be_draft }
        its(:draft_id) { should be_present }
        its(:draft) { should be_present }
        its(:name) { should eql 'Bob' }
        its(:ignored) { should eql 'Huzzah!' }

        it 'updates the existing draft' do
          expect { subject }.to_not change(Draftsman::Draft.where(:id => whitelister.draft_id), :count)
        end

        its "draft's `ignored` is updated" do
          subject.draft.reify.ignored.should eql 'Huzzah!'
        end

        it 'has a `create` draft' do
          subject.draft.should be_create
        end
      end

      context 'with existing `update` draft' do
        before do
          whitelister.save!
          whitelister.attributes = { :name => 'Sam', :ignored => 'Meh.' }
        end

        context 'with changes' do
          before { whitelister.ignored = 'Huzzah!' }
          it { should be_persisted }
          it { should be_draft }
          its(:draft_id) { should be_present }
          its(:draft) { should be_present }
          its(:draft) { should be_update }
          its(:name) { should eql 'Bob' }
          its(:ignored) { should eql 'Huzzah!' }

          it 'updates the existing draft' do
            expect { subject }.to_not change(Draftsman::Draft.where(:id => whitelister.draft_id), :count)
          end

          its "draft's `name` is not changed" do
            subject.draft.reify.name.should eql 'Sam'
          end

          its "draft's `ignored` is updated" do
            subject.draft.reify.ignored.should eql 'Huzzah!'
          end
        end

        context 'with no changes' do
          it { should be_persisted }
          it { should be_draft }
          its(:draft_id) { should be_present }
          its(:draft) { should be_present }
          its(:draft) { should be_update }
          its(:name) { should eql 'Bob' }
          its(:ignored) { should eql 'Meh.' }

          it "doesn't change the number of drafts" do
            expect { subject }.to_not change(Draftsman::Draft.where(:id => whitelister.draft_id), :count)
          end

          its "draft's `name` is not updated" do
            subject.draft.reify.name.should eql 'Sam'
          end

          its "draft's `ignored` is not updated" do
            subject.draft.reify.ignored.should eql 'Meh.'
          end
        end
      end
    end
  end

  # Not affected by this customization
  describe :draft_destroy do
  end

  # Not affected by this customization
  describe 'scopes' do
  end
end
