require 'spec_helper'

describe Whitelister do
  let(:whitelister) { Whitelister.new(name: 'Bob') }
  it { should be_draftable }

  describe '#save_draft' do
    # Not affected by this customization.
    context 'on create' do
    end

    context 'on update' do
      context 'with whitelisted change' do
        context 'without draft' do
          before do
            whitelister.save!
            whitelister.attributes = { name: 'Sam', ignored: 'Meh.' }
          end

          it 'is persisted' do
            whitelister.save_draft
            whitelister.reload
            expect(whitelister).to be_persisted
          end

          it 'is a draft' do
            whitelister.save_draft
            whitelister.reload
            expect(whitelister.draft?).to eql true
          end

          it 'has a `draft_id`' do
            whitelister.save_draft
            whitelister.reload
            expect(whitelister.draft_id).to be_present
          end

          it 'has a `draft`' do
            whitelister.save_draft
            whitelister.reload
            expect(whitelister.draft).to be_present
          end

          it 'has an `update` draft' do
            whitelister.save_draft
            whitelister.reload
            expect(whitelister.draft.update?).to eql true
          end

          it 'has its original `name`' do
            whitelister.save_draft
            whitelister.reload
            expect(whitelister.name).to eql 'Bob'
          end

          it 'has the ignored value' do
            whitelister.save_draft
            whitelister.reload
            expect(whitelister.ignored).to eql 'Meh.'
          end

          it 'creates a new draft' do
            expect { whitelister.save_draft }.to change(Draftsman::Draft, :count).by(1)
          end

          it 'has an `update` draft' do
            whitelister.save_draft
            whitelister.reload
            expect(whitelister.draft.update?).to eql true
          end

          it "updates the draft's name to `Sam`" do
            whitelister.save_draft
            whitelister.reload
            expect(whitelister.draft.reify.name).to eql 'Sam'
          end

          context 'changing back to initial state' do
            before do
              whitelister.save_draft
              whitelister.attributes = { name: 'Bob', ignored: 'Huzzah!' }
            end

            it 'is no longer a draft' do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.draft?).to eql false
            end

            it 'has its original `name`' do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.name).to eql 'Bob'
            end

            it 'updates the ignored attribute' do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.ignored).to eql 'Huzzah!'
            end

            it 'does not have a `draft_id`' do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.draft_id).to be_nil
            end

            it 'does not have a `draft`' do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.draft).to be_nil
            end

            it 'destroys the draft' do
              expect { whitelister.save_draft }.to change(Draftsman::Draft.where(id: whitelister.draft_id), :count).by(-1)
            end
          end
        end

        context 'with existing `create` draft' do
          before { whitelister.save_draft }

          context 'with changes' do
            before { whitelister.attributes = { name: 'Sam', ignored: 'Meh.' } }

            it 'is persisted' do
              whitelister.save_draft
              expect(whitelister).to be_persisted
            end

            it 'is a draft' do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.draft?).to eql true
            end

            it 'has a `draft_id`' do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.draft_id).to be_present
            end

            it 'has a `draft`' do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.draft).to be_present
            end

            it 'has a `create` draft' do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.draft.create?).to eql true
            end

            it 'updates the `name`' do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.name).to eql 'Sam'
            end

            it 'updates the existing draft' do
              expect { whitelister.save_draft }.to_not change(Draftsman::Draft.where(id: whitelister.draft_id), :count)
            end

            it "updates the draft's `name`" do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.draft.reify.name).to eql 'Sam'
            end

            it "updates the draft's ignored attribute" do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.draft.reify.ignored).to eql 'Meh.'
            end
          end

          context 'with no changes' do
            it 'is persisted' do
              whitelister.save_draft
              expect(whitelister).to be_persisted
            end

            it 'is a draft' do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.draft?).to eql true
            end

            it 'has a `draft_id`' do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.draft_id).to be_present
            end

            it 'has a `draft`' do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.draft).to be_present
            end

            it 'has a `create` draft' do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.draft.create?).to eql true
            end

            it 'keeps its original `name`' do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.name).to eql 'Bob'
            end

            it "doesn't change the number of drafts" do
              expect { whitelister.save_draft }.to_not change(Draftsman::Draft.where(id: whitelister.draft_id), :count)
            end
          end
        end

        context 'with existing `update` draft' do
          before do
            whitelister.save!
            whitelister.attributes = { name: 'Sam', ignored: 'Meh.' }
          end

          context 'with changes' do
            before { whitelister.attributes = { name: 'Steve', ignored: 'Huzzah!' } }

            it 'is persisted' do
              whitelister.save_draft
              expect(whitelister).to be_persisted
            end

            it 'is a draft' do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.draft?).to eql true
            end

            it 'has a `draft_id`' do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.draft_id).to be_present
            end

            it 'has a `draft`' do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.draft).to be_present
            end

            it 'has an `update` draft' do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.draft.update?).to eql true
            end

            it 'has its original `name`' do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.name).to eql 'Bob'
            end

            it 'has the updated ignored attribute' do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.ignored).to eql 'Huzzah!'
            end

            it 'updates the existing draft' do
              expect { whitelister.save_draft }.to_not change(Draftsman::Draft.where(id: whitelister.draft_id), :count)
            end

            it "updates its draft's `name`" do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.draft.reify.name).to eql 'Steve'
            end

            it "updates its draft's `ignored` attribute" do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.draft.reify.ignored).to eql 'Huzzah!'
            end
          end

          context 'with no changes' do
            it 'is persisted' do
              whitelister.save_draft
              expect(whitelister).to be_persisted
            end

            it 'is a draft' do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.draft?).to eql true
            end

            it 'has a `draft_id`' do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.draft_id).to be_present
            end

            it 'has a `draft`' do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.draft).to be_present
            end

            it 'has its original `name`' do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.name).to eql 'Bob'
            end

            it "doesn't change the number of drafts" do
              expect { whitelister.save_draft }.to_not change(Draftsman::Draft.where(id: whitelister.draft_id), :count)
            end

            it "does not update its draft's `name`" do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.draft.reify.name).to eql 'Sam'
            end

            it 'still has an `update` draft' do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.draft.update?).to eql true
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
            whitelister.save_draft
            expect(whitelister).to be_persisted
          end

          it 'is not a draft' do
            whitelister.save_draft
            whitelister.reload
            expect(whitelister.draft?).to eql false
          end

          it 'does not have a `draft_id`' do
            whitelister.save_draft
            whitelister.reload
            expect(whitelister.draft_id).to be_nil
          end

          it 'does not create a `draft`' do
            whitelister.save_draft
            whitelister.reload
            expect(whitelister.draft).to be_nil
          end

          it 'has the same `name`' do
            whitelister.save_draft
            whitelister.reload
            expect(whitelister.name).to eql 'Bob'
          end

          it 'has an updated ignored attribute' do
            whitelister.save_draft
            whitelister.reload
            expect(whitelister.ignored).to eql 'Huzzah!'
          end

          it 'does not create a draft' do
            expect { whitelister.save_draft }.to_not change(Draftsman::Draft, :count)
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
            whitelister.save_draft
            expect(whitelister).to be_persisted
          end

          it 'is a draft' do
            whitelister.save_draft
            whitelister.reload
            expect(whitelister.draft?).to eql true
          end

          it 'has a `draft_id`' do
            whitelister.save_draft
            whitelister.reload
            expect(whitelister.draft_id).to be_present
          end

          it 'has a `draft`' do
            whitelister.save_draft
            whitelister.reload
            expect(whitelister.draft).to be_present
          end

          it 'has the same `name`' do
            whitelister.save_draft
            whitelister.reload
            expect(whitelister.name).to eql 'Bob'
          end

          it 'has an updated ignored attribute' do
            whitelister.save_draft
            whitelister.reload
            expect(whitelister.ignored).to eql 'Huzzah!'
          end

          it 'updates the existing draft' do
            expect { whitelister.save_draft }.to_not change(Draftsman::Draft.where(id: whitelister.draft_id), :count)
          end

          it "updates its draft's `ignored` attribute" do
            whitelister.save_draft
            whitelister.reload
            expect(whitelister.draft.reify.ignored).to eql 'Huzzah!'
          end

          it 'has a `create` draft' do
            whitelister.save_draft
            whitelister.reload
            expect(whitelister.draft.create?).to eql true
          end
        end

        context 'with existing `update` draft' do
          before do
            whitelister.save!
            whitelister.attributes = { name: 'Sam', ignored: 'Meh.' }
          end

          context 'with changes' do
            before { whitelister.ignored = 'Huzzah!' }

            it 'is persisted' do
              whitelister.save_draft
              expect(whitelister).to be_persisted
            end

            it 'is a draft' do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.draft?).to eql true
            end

            it 'has a `draft_id`' do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.draft_id).to be_present
            end

            it 'has a `draft`' do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.draft).to be_present
            end

            it 'has an `update` draft' do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.draft.update?).to eql true
            end

            it 'has its original `name`' do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.name).to eql 'Bob'
            end

            it 'has an updated ignored attribute' do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.ignored).to eql 'Huzzah!'
            end

            it 'updates the existing draft' do
              expect { whitelister.save_draft }.to_not change(Draftsman::Draft.where(id: whitelister.draft_id), :count)
            end

            it "updates its draft's `name`" do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.draft.reify.name).to eql 'Sam'
            end

            it "updated its draft's `ignored` attribute" do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.draft.reify.ignored).to eql 'Huzzah!'
            end
          end

          context 'with no changes' do
            it 'is persisted' do
              whitelister.save_draft
              expect(whitelister).to be_persisted
            end

            it 'is a draft' do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.draft?).to eql true
            end

            it 'has a `draft_id`' do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.draft_id).to be_present
            end

            it 'has a `draft`' do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.draft).to be_present
            end

            it 'has an `update` draft' do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.draft.update?).to eql true
            end

            it 'has its original `name`' do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.name).to eql 'Bob'
            end

            it 'has its original `ignored` attribute' do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.ignored).to eql 'Meh.'
            end

            it "doesn't change the number of drafts" do
              expect { whitelister.save_draft }.to_not change(Draftsman::Draft.where(id: whitelister.draft_id), :count)
            end

            it "does not update its draft's `name`" do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.draft.reify.name).to eql 'Sam'
            end

            it "does not update its draft's `ignored` attribute" do
              whitelister.save_draft
              whitelister.reload
              expect(whitelister.draft.reify.ignored).to eql 'Meh.'
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
