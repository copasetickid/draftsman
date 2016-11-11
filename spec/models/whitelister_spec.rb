require 'spec_helper'

describe Whitelister do
  let(:whitelister) { Whitelister.new :name => 'Bob' }
  it { should be_draftable }

  describe '#save_draft' do
    # Not affected by this customization.
    context 'on create' do
    end

    context 'on update' do
      subject do
        whitelister.save_draft
        whitelister.reload
      end

      context 'with whitelisted change' do
        context 'without draft' do
          before do
            whitelister.save!
            whitelister.attributes = { :name => 'Sam', :ignored => 'Meh.' }
          end

          it 'is persisted' do
            expect(subject).to be_persisted
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

          it 'has an `update` draft' do
            expect(subject.draft.update?).to eql true
          end

          it 'has its original `name`' do
            expect(subject.name).to eql 'Bob'
          end

          it 'has the ignored value' do
            expect(subject.ignored).to eql 'Meh.'
          end

          it 'creates a new draft' do
            expect { subject }.to change(Draftsman::Draft, :count).by(1)
          end

          it 'has an `update` draft' do
            expect(subject.draft.update?).to eql true
          end

          it "updates the draft's name to `Sam`" do
            expect(subject.draft.reify.name).to eql 'Sam'
          end

          context 'changing back to initial state' do
            before do
              whitelister.save_draft
              whitelister.attributes = { :name => 'Bob', :ignored => 'Huzzah!' }
            end

            it 'is no longer a draft' do
              expect(subject.draft?).to eql false
            end

            it 'has its original `name`' do
              expect(subject.name).to eql 'Bob'
            end

            it 'updates the ignored attribute' do
              expect(subject.ignored).to eql 'Huzzah!'
            end

            it 'does not have a `draft_id`' do
              expect(subject.draft_id).to be_nil
            end

            it 'does not have a `draft`' do
              expect(subject.draft).to be_nil
            end

            it 'destroys the draft' do
              expect { subject }.to change(Draftsman::Draft.where(:id => whitelister.draft_id), :count).by(-1)
            end
          end
        end

        context 'with existing `create` draft' do
          before { whitelister.save_draft }

          context 'with changes' do
            before { whitelister.attributes = { :name => 'Sam', :ignored => 'Meh.' } }

            it 'is persisted' do
              expect(subject).to be_persisted
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

            it 'has a `create` draft' do
              expect(subject.draft.create?).to eql true
            end

            it 'updates the `name`' do
              expect(subject.name).to eql 'Sam'
            end

            it 'updates the existing draft' do
              expect { subject }.to_not change(Draftsman::Draft.where(:id => whitelister.draft_id), :count)
            end

            it "updates the draft's `name`" do
              expect(subject.draft.reify.name).to eql 'Sam'
            end

            it "updates the draft's ignored attribute" do
              expect(subject.draft.reify.ignored).to eql 'Meh.'
            end
          end

          context 'with no changes' do
            it 'is persisted' do
              expect(subject).to be_persisted
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

            it 'has a `create` draft' do
              expect(subject.draft.create?).to eql true
            end

            it 'keeps its original `name`' do
              expect(subject.name).to eql 'Bob'
            end

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

            it 'is persisted' do
              expect(subject).to be_persisted
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

            it 'has an `update` draft' do
              expect(subject.draft.update?).to eql true
            end

            it 'has its original `name`' do
              expect(subject.name).to eql 'Bob'
            end

            it 'has the updated ignored attribute' do
              expect(subject.ignored).to eql 'Huzzah!'
            end

            it 'updates the existing draft' do
              expect { subject }.to_not change(Draftsman::Draft.where(:id => whitelister.draft_id), :count)
            end

            it "updates its draft's `name`" do
              expect(subject.draft.reify.name).to eql 'Steve'
            end

            it "updates its draft's `ignored` attribute" do
              expect(subject.draft.reify.ignored).to eql 'Huzzah!'
            end
          end

          context 'with no changes' do
            it 'is persisted' do
              expect(subject).to be_persisted
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

            it 'has its original `name`' do
              expect(subject.name).to eql 'Bob'
            end

            it "doesn't change the number of drafts" do
              expect { subject }.to_not change(Draftsman::Draft.where(:id => whitelister.draft_id), :count)
            end

            it "does not update its draft's `name`" do
              expect(subject.draft.reify.name).to eql 'Sam'
            end

            it 'still has an `update` draft' do
              expect(subject.draft.update?).to eql true
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

          it 'is persisted' do
            expect(subject).to be_persisted
          end

          it 'is not a draft' do
            expect(subject.draft?).to eql false
          end

          it 'does not have a `draft_id`' do
            expect(subject.draft_id).to be_nil
          end

          it 'does not create a `draft`' do
            expect(subject.draft).to be_nil
          end

          it 'has the same `name`' do
            expect(subject.name).to eql 'Bob'
          end

          it 'has an updated ignored attribute' do
            expect(subject.ignored).to eql 'Huzzah!'
          end

          it 'does not create a draft' do
            expect { subject }.to_not change(Draftsman::Draft, :count)
          end

          # Not affected by this customization
          context 'changing back to initial state' do
          end
        end

        context 'with existing `create` draft' do
          before do
            whitelister.save_draft
            whitelister.ignored = 'Huzzah!'
          end

          it 'is persisted' do
            expect(subject).to be_persisted
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

          it 'has the same `name`' do
            expect(subject.name).to eql 'Bob'
          end

          it 'has an updated ignored attribute' do
            expect(subject.ignored).to eql 'Huzzah!'
          end

          it 'updates the existing draft' do
            expect { subject }.to_not change(Draftsman::Draft.where(:id => whitelister.draft_id), :count)
          end

          it "updates its draft's `ignored` attribute" do
            expect(subject.draft.reify.ignored).to eql 'Huzzah!'
          end

          it 'has a `create` draft' do
            expect(subject.draft.create?).to eql true
          end
        end

        context 'with existing `update` draft' do
          before do
            whitelister.save!
            whitelister.attributes = { :name => 'Sam', :ignored => 'Meh.' }
          end

          context 'with changes' do
            before { whitelister.ignored = 'Huzzah!' }

            it 'is persisted' do
              expect(subject).to be_persisted
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

            it 'has an `update` draft' do
              expect(subject.draft.update?).to eql true
            end

            it 'has its original `name`' do
              expect(subject.name).to eql 'Bob'
            end

            it 'has an updated ignored attribute' do
              expect(subject.ignored).to eql 'Huzzah!'
            end

            it 'updates the existing draft' do
              expect { subject }.to_not change(Draftsman::Draft.where(:id => whitelister.draft_id), :count)
            end

            it "updates its draft's `name`" do
              expect(subject.draft.reify.name).to eql 'Sam'
            end

            it "updated its draft's `ignored` attribute" do
              expect(subject.draft.reify.ignored).to eql 'Huzzah!'
            end
          end

          context 'with no changes' do
            it 'is persisted' do
              expect(subject).to be_persisted
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

            it 'has an `update` draft' do
              expect(subject.draft.update?).to eql true
            end

            it 'has its original `name`' do
              expect(subject.name).to eql 'Bob'
            end

            it 'has its original `ignored` attribute' do
              expect(subject.ignored).to eql 'Meh.'
            end

            it "doesn't change the number of drafts" do
              expect { subject }.to_not change(Draftsman::Draft.where(:id => whitelister.draft_id), :count)
            end

            it "does not update its draft's `name`" do
              expect(subject.draft.reify.name).to eql 'Sam'
            end

            it "does not update its draft's `ignored` attribute" do
              expect(subject.draft.reify.ignored).to eql 'Meh.'
            end
          end
        end
      end
    end
  end

  # Not affected by this customization
  describe '#draft_destruction' do
  end

  # Not affected by this customization
  describe 'scopes' do
  end
end
