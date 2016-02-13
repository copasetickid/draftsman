require 'spec_helper'

# A Vanilla has a simple call to `has_drafts` without any options specified.
describe Vanilla do
  let(:vanilla) { Vanilla.new :name => 'Bob' }
  it { should be_draftable }

  describe 'draft_creation' do
    subject do
      vanilla.draft_creation
      vanilla.reload
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
      expect(subject.draft.create?).to eql true
    end

    it 'saves the `name`' do
      expect(subject.name).to eql 'Bob'
    end
  end

  describe 'draft_update' do
    subject do
      vanilla.draft_update
      vanilla.reload
    end

    context 'without existing draft' do
      before do
        vanilla.save!
        vanilla.name = 'Sam'
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

      it 'is no longer a draft' do
        expect(subject.draft?).to eql false
      end

      it 'has the original `name`' do
        expect(subject.name).to eql 'Bob'
      end

      it 'does not have a `draft_id`' do
        expect(subject.draft_id).to be_nil
      end

      it 'has no `draft`' do
        expect(subject.draft).to be_nil
      end

      it 'destroys the draft' do
        expect { subject }.to change(Draftsman::Draft.where(:id => vanilla.draft_id), :count).by(-1)
      end
    end

    context 'with existing `create` draft' do
      before { vanilla.draft_creation }

      context 'with changes' do
        before { vanilla.name = 'Sam' }
        
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

        it 'records the new `name`' do
          expect(subject.name).to eql 'Sam'
        end

        it 'updates the existing draft' do
          expect { subject }.to_not change(Draftsman::Draft.where(:id => vanilla.draft_id), :count)
        end

        it "updates the draft's `name`" do
          expect(subject.draft.reify.name).to eql 'Sam'
        end

        it 'has a `create` draft' do
          expect(subject.draft.create?).to eql true
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

        it 'has the same `name`' do
          expect(subject.name).to eql 'Bob'
        end

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
        vanilla.reload
        vanilla.attributes = vanilla.draft.reify.attributes
      end

      context 'with changes' do
        before { vanilla.name = 'Steve' }
        
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

        it 'has the original `name`' do
          expect(subject.name).to eql 'Bob'
        end

        it 'updates the existing draft' do
          expect { subject }.to_not change(Draftsman::Draft.where(:id => vanilla.draft_id), :count)
        end

        it "updates the draft's `name`" do
          expect(subject.draft.reify.name).to eql 'Steve'
        end

        it 'has a `create` draft' do
          expect(subject.draft.update?).to eql true
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

        it "doesn't change the number of drafts" do
          expect { subject }.to_not change(Draftsman::Draft.where(:id => vanilla.draft_id), :count)
        end

        it "does not update the draft's `name`" do
          expect(subject.draft.reify.name).to eql 'Sam'
        end
      end
    end
  end

  # Not applicable to this customization
  describe 'draft_destruction' do
  end

  describe 'scopes' do
    let!(:drafted_vanilla)   { vanilla.draft_creation; return vanilla }
    let!(:published_vanilla) { Vanilla.create :name => 'Jane', :published_at => Time.now }

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
        expect { subject.load }.to raise_exception
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
        expect { subject.load }.to raise_exception
      end
    end
  end
end
