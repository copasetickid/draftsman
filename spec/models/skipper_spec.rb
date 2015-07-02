require 'spec_helper'

describe Skipper do
  let(:skipper) { Skipper.new :name => 'Bob', :skip_me => 'Skipped 1' }

  it 'is draftable' do
    expect(subject.class.draftable?).to eql true
  end

  describe 'draft_creation' do
    subject do
      skipper.draft_creation
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
  end

  describe 'draft_update' do
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
        expect(subject.skip_me).to eql 'Skipped 2'
      end

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

      it 'is no longer a draft' do
        expect(subject.draft?).to eql false
      end

      it 'no longer has a `draft_id`' do
        expect(subject.draft_id).to be_nil
      end

      it 'no longer has a `draft`' do
        expect(subject.draft).to be_nil
      end

      it 'has its original `name`' do
        expect(subject.name).to eql 'Bob'
      end

      it "retains the updated skipped attribute's value" do
        expect(subject.skip_me).to eql 'Skipped 2'
      end

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

        it 'has the updated `name`' do
          expect(subject.name).to eql 'Sam'
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

        it 'has the original `name`' do
          expect(subject.name).to eql 'Bob'
        end

        it "has the original skipped attribute's value" do
          expect(subject.skip_me).to eql 'Skipped 1'
        end

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
          expect(subject.skip_me).to eql 'Skipped 2'
        end

        it 'updates the existing draft' do
          expect { subject }.to_not change(Draftsman::Draft.where(:id => skipper.draft_id), :count)
        end

        it "updates the draft's `name`" do
          expect(subject.draft.reify.name).to eql 'Steve'
        end
        
        it "updates skipped attribute while also updating draft attribute" do
          subject.name = 'Tom'
          subject.skip_me = 'Skip and save'
          subject.draft_update

          subject.reload
          
          expect(subject.skip_me).to eql 'Skip and save'
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
          expect(subject.skip_me).to eql 'Skipped 2'
        end

        it "doesn't change the number of drafts" do
          expect { subject }.to_not change(Draftsman::Draft.where(:id => skipper.draft_id), :count)
        end

        it "does not update the draft's `name`" do
          expect(subject.draft.reify.name).to eql 'Sam'
        end
      end
    end
  end

  # Not applicable to this customization
  describe 'draft_destroy' do
  end

  # Not applicable to this customization
  describe 'scopes' do
  end
end
