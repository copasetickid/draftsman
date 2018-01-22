require 'spec_helper'

# A Vanilla has a simple call to `has_drafts` without any options specified.
describe Vanilla do
  let(:vanilla) { Vanilla.new(name: 'Bob') }
  it { should be_draftable }

  describe '#draftsman_options' do    
    describe '[:publish_options]' do
      subject { vanilla.draftsman_options[:publish_options] }

      it { is_expected.to be_present }
      it { is_expected.to be_a(Hash) }
      it { is_expected.to include(validate: false) }
    end
  end

  describe '#object_attrs_for_draft_record' do
    it 'contains column name' do
      expect(vanilla.object_attrs_for_draft_record).to include 'name'
    end

    it 'contains column updated_at' do
      expect(vanilla.object_attrs_for_draft_record).to include 'updated_at'
    end

    it 'contains column created_at' do
      expect(vanilla.object_attrs_for_draft_record).to include 'created_at'
    end
  end

  describe '#save_draft' do
    context 'on create' do
      it 'is persisted' do
        vanilla.save_draft
        expect(vanilla).to be_persisted
      end

      it 'is a draft' do
        vanilla.save_draft
        expect(vanilla.draft?).to eql true
      end

      it 'has a `draft_id`' do
        vanilla.save_draft
        expect(vanilla.draft_id).to be_present
      end

      it 'has a `draft`' do
        vanilla.save_draft
        expect(vanilla.draft).to be_present
      end

      it 'has a `create` draft' do
        vanilla.save_draft
        expect(vanilla.draft.create?).to eql true
      end

      it 'saves the `name`' do
        vanilla.save_draft
        expect(vanilla.name).to eql 'Bob'
      end

      it 'sets `updated_at`' do
        time = Time.now
        vanilla.save_draft
        expect(vanilla.updated_at).to be > time
      end

      it 'sets `created_at`' do
        time = Time.now
        vanilla.save_draft
        expect(vanilla.created_at).to be > time
      end
    end

    context 'on update' do
      context 'with stashed drafted changes' do
        context 'without existing draft' do
          before do
            vanilla.save!
            vanilla.name = 'Sam'
          end

          it 'is persisted' do
            vanilla.save_draft
            expect(vanilla).to be_persisted
          end

          it 'is a draft' do
            vanilla.save_draft
            vanilla.reload
            expect(vanilla.draft?).to eql true
          end

          it 'has a `draft_id`' do
            vanilla.save_draft
            vanilla.reload
            expect(vanilla.draft_id).to be_present
          end

          it 'has a `draft`' do
            vanilla.save_draft
            vanilla.reload
            expect(vanilla.draft).to be_present
          end

          it 'has an `update` draft' do
            vanilla.save_draft
            vanilla.reload
            expect(vanilla.draft.update?).to eql true
          end

          it 'has the original `name`' do
            vanilla.save_draft
            vanilla.reload
            expect(vanilla.reload.name).to eql 'Bob'
          end

          it 'creates a new draft' do
            expect { vanilla.save_draft }.to change(Draftsman::Draft, :count).by(1)
          end

          it 'has the original `updated_at`' do
            vanilla.save_draft
            vanilla.reload
            expect(vanilla.updated_at).to eq vanilla.created_at
          end
        end

        describe 'changing back to initial state' do
          before do
            vanilla.published_at = Time.now
            vanilla.save!
            vanilla.name = 'Sam'
            vanilla.save_draft
            vanilla.reload
            vanilla.name = 'Bob'
          end

          it 'is no longer a draft' do
            vanilla.save_draft
            vanilla.reload
            expect(vanilla.draft?).to eql false
          end

          it 'has the original `name`' do
            vanilla.save_draft
            vanilla.reload
            expect(vanilla.reload.name).to eql 'Bob'
          end

          it 'does not have a `draft_id`' do
            vanilla.save_draft
            vanilla.reload
            expect(vanilla.draft_id).to be_nil
          end

          it 'has no `draft`' do
            vanilla.save_draft
            vanilla.reload
            expect(vanilla.draft).to be_nil
          end

          it 'destroys the draft' do
            expect { vanilla.save_draft }.to change(Draftsman::Draft.where(id: vanilla.draft_id), :count).by(-1)
          end

          it 'has the original `updated_at`' do
            if activerecord_save_touch_option?
              vanilla.save_draft
              vanilla.reload
              expect(vanilla.updated_at).to eq vanilla.created_at
            end
          end
        end

        context 'with existing `create` draft' do
          before { vanilla.save_draft }

          context 'with changes' do
            before { vanilla.name = 'Sam' }

            it 'is persisted' do
              vanilla.save_draft
              vanilla.reload
              expect(vanilla).to be_persisted
            end

            it 'is a draft' do
              vanilla.save_draft
              vanilla.reload
              expect(vanilla.draft?).to eql true
            end

            it 'has a `draft_id`' do
              vanilla.save_draft
              vanilla.reload
              expect(vanilla.draft_id).to be_present
            end

            it 'has a `draft`' do
              vanilla.save_draft
              vanilla.reload
              expect(vanilla.draft).to be_present
            end

            it 'records the new `name`' do
              vanilla.save_draft
              vanilla.reload
              expect(vanilla.reload.name).to eql 'Sam'
            end

            it 'updates the existing draft' do
              expect { vanilla.save_draft }.to_not change(Draftsman::Draft.where(id: vanilla.draft_id), :count)
            end

            it "updates the draft's `name`" do
              vanilla.save_draft
              vanilla.reload
              expect(vanilla.draft.reify.name).to eql 'Sam'
            end

            it 'has a `create` draft' do
              vanilla.save_draft
              vanilla.reload
              expect(vanilla.draft.create?).to eql true
            end

            it 'has a new `updated_at`' do
              time = vanilla.updated_at
              vanilla.save_draft
              vanilla.reload
              expect(vanilla.updated_at).to be > time
            end
          end # with changes

          context 'with no changes' do
            it 'is persisted' do
              vanilla.save_draft
              expect(vanilla).to be_persisted
            end

            it 'is a draft' do
              vanilla.save_draft
              vanilla.reload
              expect(vanilla.draft?).to eql true
            end

            it 'has a `draft_id`' do
              vanilla.save_draft
              vanilla.reload
              expect(vanilla.draft_id).to be_present
            end

            it 'has a `draft`' do
              vanilla.save_draft
              vanilla.reload
              expect(vanilla.draft).to be_present
            end

            it 'has a `create` draft' do
              vanilla.save_draft
              vanilla.reload
              expect(vanilla.draft.create?).to eql true
            end

            it 'has the same `name`' do
              vanilla.save_draft
              vanilla.reload
              expect(vanilla.reload.name).to eql 'Bob'
            end

            it "doesn't change the number of drafts" do
              expect { vanilla.save_draft }.to_not change(Draftsman::Draft.where(id: vanilla.draft_id), :count)
            end

            it 'has the original `updated_at`' do
              vanilla.save_draft
              vanilla.reload
              expect(vanilla.updated_at).to eq vanilla.created_at
            end
          end
        end # with no changes

        context 'with existing `update` draft' do
          before do
            vanilla.save!
            vanilla.name = 'Sam'
            vanilla.save_draft
            vanilla.reload
            vanilla.attributes = vanilla.draft.reify.attributes
          end

          context 'with changes' do
            before { vanilla.name = 'Steve' }

            it 'is persisted' do
              vanilla.save_draft
              expect(vanilla).to be_persisted
            end

            it 'is a draft' do
              vanilla.save_draft
              vanilla.reload
              expect(vanilla.draft?).to eql true
            end

            it 'has a `draft_id`' do
              vanilla.save_draft
              vanilla.reload
              expect(vanilla.draft_id).to be_present
            end

            it 'has a `draft`' do
              vanilla.save_draft
              vanilla.reload
              expect(vanilla.draft).to be_present
            end

            it 'has the original `name`' do
              vanilla.save_draft
              vanilla.reload
              expect(vanilla.reload.name).to eql 'Bob'
            end

            it 'updates the existing draft' do
              expect { vanilla.save_draft }.to_not change(Draftsman::Draft.where(id: vanilla.draft_id), :count)
            end

            it "updates the draft's `name`" do
              vanilla.save_draft
              vanilla.reload
              expect(vanilla.draft.reify.name).to eql 'Steve'
            end

            it 'has an `update` draft' do
              vanilla.save_draft
              expect(vanilla.draft.update?).to eql true
            end

            it 'has the original `updated_at`' do
              vanilla.save_draft
              vanilla.reload
              expect(vanilla.updated_at).to eq vanilla.created_at
            end
          end # with changes

          context 'with no changes' do
            it 'is persisted' do
              vanilla.save_draft
              expect(vanilla).to be_persisted
            end

            it 'is a draft' do
              vanilla.save_draft
              vanilla.reload
              expect(vanilla.draft?).to eql true
            end

            it 'has a `draft_id`' do
              vanilla.save_draft
              vanilla.reload
              expect(vanilla.draft_id).to be_present
            end

            it 'has a `draft`' do
              vanilla.save_draft
              vanilla.reload
              expect(vanilla.draft).to be_present
            end

            it 'has an `update` draft' do
              vanilla.save_draft
              vanilla.reload
              expect(vanilla.draft.update?).to eql true
            end

            it 'has the original `name`' do
              vanilla.save_draft
              vanilla.reload
              expect(vanilla.reload.name).to eql 'Bob'
            end

            it "doesn't change the number of drafts" do
              expect { vanilla.save_draft }.to_not change(Draftsman::Draft.where(id: vanilla.draft_id), :count)
            end

            it "does not update the draft's `name`" do
              vanilla.save_draft
              vanilla.reload
              expect(vanilla.draft.reify.name).to eql 'Sam'
            end

            it 'has the original `updated_at`' do
              vanilla.save_draft
              vanilla.reload
              expect(vanilla.updated_at).to eq vanilla.created_at
            end
          end # with no changes
        end # with existing `update` draft
      end # with stashed drafted changes

      context 'without stashed drafted changes' do
        before { Draftsman.stash_drafted_changes = false }
        after { Draftsman.stash_drafted_changes = true }

        context 'without existing draft' do
          before do
            vanilla.save!
            vanilla.name = 'Sam'
          end

          it 'is persisted' do
            vanilla.save_draft
            expect(vanilla).to be_persisted
          end

          it 'is a draft' do
            vanilla.save_draft
            vanilla.reload
            expect(vanilla.draft?).to eql true
          end

          it 'has a `draft_id`' do
            vanilla.save_draft
            vanilla.reload
            expect(vanilla.draft_id).to be_present
          end

          it 'has a `draft`' do
            vanilla.save_draft
            vanilla.reload
            expect(vanilla.draft).to be_present
          end

          it 'has an `update` draft' do
            vanilla.save_draft
            vanilla.reload
            expect(vanilla.draft.update?).to eql true
          end

          it 'has the new `name`' do
            vanilla.save_draft
            vanilla.reload
            expect(vanilla.reload.name).to eql 'Sam'
          end

          it 'creates a new draft' do
            expect { vanilla.save_draft }.to change(Draftsman::Draft, :count).by(1)
          end

          it 'has a new `updated_at`' do
            time = vanilla.updated_at
            vanilla.save_draft
            vanilla.reload
            expect(vanilla.updated_at).to be > time
          end
        end

        describe 'changing back to initial state' do
          before do
            vanilla.published_at = Time.now
            vanilla.save!
            vanilla.name = 'Sam'
            vanilla.save_draft
            vanilla.reload
            vanilla.name = 'Bob'
          end

          it 'is no longer a draft' do
            vanilla.save_draft
            vanilla.reload
            expect(vanilla.draft?).to eql false
          end

          it 'has the original `name`' do
            vanilla.save_draft
            vanilla.reload
            expect(vanilla.reload.name).to eql 'Bob'
          end

          it 'does not have a `draft_id`' do
            vanilla.save_draft
            vanilla.reload
            expect(vanilla.draft_id).to be_nil
          end

          it 'has no `draft`' do
            vanilla.save_draft
            vanilla.reload
            expect(vanilla.draft).to be_nil
          end

          it 'destroys the draft' do
            expect { vanilla.save_draft }.to change(Draftsman::Draft.where(id: vanilla.draft_id), :count).by(-1)
          end

          it 'has a new `updated_at`' do
            time = vanilla.updated_at
            vanilla.save_draft
            vanilla.reload
            expect(vanilla.updated_at).to be > time
          end
        end

        context 'with existing `create` draft' do
          before { vanilla.save_draft }

          context 'with changes' do
            before { vanilla.name = 'Sam' }

            it 'is persisted' do
              vanilla.save_draft
              expect(vanilla).to be_persisted
            end

            it 'is a draft' do
              vanilla.save_draft
              expect(vanilla.draft?).to eql true
            end

            it 'has a `draft_id`' do
              vanilla.save_draft
              expect(vanilla.draft_id).to be_present
            end

            it 'has a `draft`' do
              vanilla.save_draft
              expect(vanilla.draft).to be_present
            end

            it 'records the new `name`' do
              vanilla.save_draft
              expect(vanilla.reload.name).to eql 'Sam'
            end

            it 'updates the existing draft' do
              expect { vanilla.save_draft }.to_not change(Draftsman::Draft.where(id: vanilla.draft_id), :count)
            end

            it "updates the draft's `name`" do
              vanilla.save_draft
              expect(vanilla.draft.reify.name).to eql 'Sam'
            end

            it 'has a `create` draft' do
              vanilla.save_draft
              expect(vanilla.draft.create?).to eql true
            end

            it 'has a new `updated_at`' do
              time = vanilla.updated_at
              vanilla.save_draft
              vanilla.reload
              expect(vanilla.updated_at).to be > time
            end
          end

          context 'with no changes' do
            it 'is persisted' do
              vanilla.save_draft
              expect(vanilla).to be_persisted
            end

            it 'is a draft' do
              vanilla.save_draft
              expect(vanilla.draft?).to eql true
            end

            it 'has a `draft_id`' do
              expect(vanilla.draft_id).to be_present
            end

            it 'has a `draft`' do
              vanilla.save_draft
              expect(vanilla.draft).to be_present
            end

            it 'has a `create` draft' do
              vanilla.save_draft
              expect(vanilla.draft.create?).to eql true
            end

            it 'has the same `name`' do
              vanilla.save_draft
              expect(vanilla.reload.name).to eql 'Bob'
            end

            it "doesn't change the number of drafts" do
              expect { vanilla.save_draft }.to_not change(Draftsman::Draft.where(id: vanilla.draft_id), :count)
            end

            it 'has the original `updated_at`' do
              vanilla.save_draft
              expect(vanilla.reload.updated_at).to eq vanilla.created_at
            end
          end
        end

        context 'with existing `update` draft' do
          before do
            vanilla.save!
            vanilla.name = 'Sam'
            vanilla.save_draft
            vanilla.reload
          end

          context 'with changes' do
            before { vanilla.name = 'Steve' }

            it 'is persisted' do
              vanilla.save_draft
              vanilla.reload
              expect(vanilla).to be_persisted
            end

            it 'is a draft' do
              vanilla.save_draft
              vanilla.reload
              expect(vanilla.draft?).to eql true
            end

            it 'has a `draft_id`' do
              vanilla.save_draft
              vanilla.reload
              expect(vanilla.draft_id).to be_present
            end

            it 'has a `draft`' do
              vanilla.save_draft
              vanilla.reload
              expect(vanilla.draft).to be_present
            end

            it 'has the new `name`' do
              vanilla.save_draft
              vanilla.reload
              expect(vanilla.reload.name).to eql 'Steve'
            end

            it 'updates the existing draft' do
              expect { vanilla.save_draft }.to_not change(Draftsman::Draft.where(id: vanilla.draft_id), :count)
            end

            it "updates the draft's `name`" do
              vanilla.save_draft
              vanilla.reload
              expect(vanilla.draft.reify.name).to eql 'Steve'
            end

            it 'has an `update` draft' do
              vanilla.save_draft
              vanilla.reload
              expect(vanilla.draft.update?).to eql true
            end

            it 'has a new `updated_at`' do
              time = vanilla.updated_at
              vanilla.save_draft
              vanilla.reload
              expect(vanilla.updated_at).to be > time
            end
          end # with changes

          context 'with no changes' do
            it 'is persisted' do
              vanilla.save_draft
              expect(vanilla).to be_persisted
            end

            it 'is a draft' do
              vanilla.save_draft
              expect(vanilla.draft?).to eql true
            end

            it 'has a `draft_id`' do
              vanilla.save_draft
              expect(vanilla.draft_id).to be_present
            end

            it 'has a `draft`' do
              vanilla.save_draft
              expect(vanilla.draft).to be_present
            end

            it 'has an `update` draft' do
              vanilla.save_draft
              expect(vanilla.draft.update?).to eql true
            end

            it 'has the original `name`' do
              vanilla.save_draft
              expect(vanilla.reload.name).to eql 'Sam'
            end

            it "doesn't change the number of drafts" do
              expect { vanilla.save_draft }.to_not change(Draftsman::Draft.where(id: vanilla.draft_id), :count)
            end

            it "does not update the draft's `name`" do
              vanilla.save_draft
              expect(vanilla.draft.reify.name).to eql 'Sam'
            end

            it 'does not update `updated_at`' do
              time = vanilla.updated_at
              vanilla.save_draft
              vanilla.reload
              expect(vanilla.updated_at).to eq time
            end
          end # with no changes
        end # with existing `update` draft
      end # without stashed drafted changes
    end # on update
  end

  # Not applicable to this customization
  describe '#draft_destruction' do
  end

  describe 'scopes' do
    let!(:drafted_vanilla)   { vanilla.save_draft; return vanilla }
    let!(:published_vanilla) { Vanilla.create(name: 'Jane', published_at: Time.now) }

    describe 'drafted' do
      subject { Vanilla.drafted }

      it 'returns 1 record' do
        expect(subject.count).to eql 1
      end

      it 'includes the drafted record' do
        expect(subject).to include drafted_vanilla
      end

      it 'does not include the published record' do
        expect(subject).to_not include published_vanilla
      end
    end

    describe 'live' do
      subject { Vanilla.live }

      it 'raises an exception' do
        expect { subject.load }.to raise_exception(ActiveRecord::StatementInvalid)
      end
    end

    describe 'published' do
      subject { Vanilla.published }

      it 'returns 1 record' do
        expect(subject.count).to eql 1
      end

      it 'does not include the drafted record' do
        expect(subject).to_not include drafted_vanilla
      end

      it 'includes the published record' do
        expect(subject).to include published_vanilla
      end
    end

    describe 'trashed' do
      subject { Vanilla.trashed }

      it 'raises an exception' do
        expect { subject.load }.to raise_exception(ActiveRecord::StatementInvalid)
      end
    end
  end
end
