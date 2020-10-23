require 'spec_helper'

RSpec.describe Skipper, type: :model do
  let(:skipper) { Skipper.new(name: 'Bob', skip_me: 'Skipped 1') }

  describe '.draftable?' do
    it 'is `true`' do
      expect(subject.class.draftable?).to eql true
    end
  end

  describe '#object_attrs_for_draft_record' do
    it 'contains changed but not skipped column name' do
      expect(skipper.object_attrs_for_draft_record).to include 'name'
    end

    it 'does not contain the skipped column name' do
      expect(skipper.object_attrs_for_draft_record).to_not include 'skip_me'
    end
  end

  describe '#save_draft' do
    context 'on create' do
      subject do
        skipper.save_draft
        skipper.reload
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

      it 'has a draft' do
        expect(subject.draft).to be_present
      end

      it 'has a `create` draft' do
        expect(subject.draft.create?).to eql true
      end

      it 'has a `name`' do
        expect(subject.name).to eql 'Bob'
      end

      it 'has a value for `skip_me`' do
        expect(subject.skip_me).to eql 'Skipped 1'
      end

      it 'sets `updated_at`' do
        time = Time.now
        expect(subject.updated_at).to be > time
      end
    end

    context 'on update' do
      subject do
        skipper.save_draft
        skipper.reload
      end

      context 'without existing draft' do
        before do
          skipper.save!
          skipper.name = 'Sam'
          skipper.skip_me = 'Skipped 2'
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

        it 'identifies as an `update` draft' do
          expect(subject.draft.update?).to eql true
        end

        it 'has the original name' do
          expect(subject.name).to eql 'Bob'
        end

        it 'has the updated skipped attribute' do
          expect(subject.skip_me).to eql 'Skipped 1'
        end

        it 'creates a new draft' do
          expect { subject }.to change(Draftsman::Draft, :count).by(1)
        end

        it 'has a newer `updated_at`' do
          time = skipper.updated_at
          expect(subject.updated_at).to be > time
        end
      end

      context 'with existing `create` draft' do
        before do
          skipper.save_draft
          skipper.reload
        end

        context 'with changes' do
          before do
            skipper.name = 'Sam'
            skipper.skip_me = 'Skipped 2'
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

          it 'has a `create` draft' do
            expect(subject.draft.event).to eql 'update'
          end

          it 'has the updated `name`' do
            expect(subject.name).to eql 'Bob'
          end

          it "retains the updated skipped attribute's value" do
            expect(subject.skip_me).to eql 'Skipped 2'
          end

          it 'updates the existing draft' do
            expect { subject }.to_not change(Draftsman::Draft.where(:id => skipper.draft_id), :count)
          end

          it "updates the draft's `name`" do
            expect(subject.draft.reify.name).to eql 'Sam'
          end

          it 'has a newer `updated_at`' do
            time = skipper.updated_at
            expect(subject.updated_at).to be > time
          end
        end

        context 'with changes to drafted attribute' do
          before do
            skipper.name = 'Sam'
          end
        end

        context 'with changes to skipped attribute' do
          before do
            skipper.skip_me = 'Skipped 2'
          end

          it 'has a newer `updated_at`' do
            time = skipper.updated_at
            expect(subject.updated_at).to be > time
          end
        end

      end

      context 'with existing `update` draft' do
        before do
          skipper.save!
          skipper.name = 'Sam'
          skipper.skip_me = 'Skipped 2'
          skipper.save_draft
          skipper.reload
          skipper.attributes = skipper.draft.reify.attributes
        end

        context 'with changes to drafted attribute' do
          before { skipper.name = 'Steve' }

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

          it 'has the original `name`' do
            expect(subject.name).to eql 'Bob'
          end

          it "has the updated skipped attribute's value" do
            expect(subject.skip_me).to eql 'Skipped 1'
          end

          it 'updates the existing draft' do
            expect { subject }.to_not change(Draftsman::Draft.where(:id => skipper.draft_id), :count)
          end

          it "updates the draft's `name`" do
            expect(subject.draft.reify.name).to eql 'Steve'
          end

          it 'has the original `updated_at`' do
            time = skipper.updated_at
            expect(subject.updated_at).to eq time
          end
        end

        context 'with changes to skipped attributes' do
          before do
            skipper.skip_me = 'Skip and save'
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

          it 'has the original `name`' do
            expect(subject.name).to eql 'Bob'
          end

          it "updates skipped attribute's value" do
            expect(subject.skip_me).to eql 'Skip and save'
          end

          it 'updates the existing draft' do
            expect { subject }.to_not change(Draftsman::Draft.where(:id => skipper.draft_id), :count)
          end

          it "keeps the draft's `name`" do
            expect(subject.draft.reify.name).to eql 'Sam'
          end

          it 'updates skipped attribute on draft' do
            expect(subject.draft.reify.skip_me).to eql 'Skip and save'
          end

          it 'has a newer `updated_at`' do
            time = skipper.updated_at
            expect(subject.updated_at).to be > time
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

          it 'has the original `name`' do
            expect(subject.name).to eql 'Bob'
          end

          it "has the updated skipped attributes' value" do
            expect(subject.skip_me).to eql 'Skipped 1'
          end

          it "doesn't change the number of drafts" do
            expect { subject }.to_not change(Draftsman::Draft.where(:id => skipper.draft_id), :count)
          end

          it "does not update the draft's `name`" do
            expect(subject.draft.reify.name).to eql 'Sam'
          end

          it 'has the original `updated_at`' do
            time = skipper.updated_at
            expect(subject.updated_at).to eq time
          end
        end
      end
    end
  end

  # Not applicable to this customization
  describe 'draft_destruction' do
  end

  # Not applicable to this customization
  describe 'scopes' do
  end
end
