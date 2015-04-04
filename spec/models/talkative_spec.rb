require 'spec_helper'

# A Talkative has a call to `has_drafts` and all nine callbacks defined:
#  before_draft_creation, around_draft_creation, after_draft_creation
#  before_draft_update, around_draft_update, after_draft_update
#  before_draft_destroy, around_draft_destroy, after_draft_destroy

describe 'Talkative' do
  let(:talkative) { Talkative.new }

  it 'is draftable' do
    expect(talkative.class.draftable?).to eql true
  end


  describe 'draft_creation' do
    before do
      talkative.draft_creation
    end

    context 'before callback' do
      it 'updates attribute' do
        expect(talkative.before_comment).to eql "I changed before creation"
      end

      it 'persists updated attribute to draft' do
        talkative.reload
        expect(talkative.draft.reify.before_comment).to eql "I changed before creation"
      end
    end

    context 'around callback' do
      it 'updates attribute (before yield)' do
        expect(talkative.around_early_comment).to eql "I changed around creation (before yield)"
      end

      it 'persists updated attribute to draft' do
        talkative.reload
        expect(talkative.draft.reify.around_late_comment).to be_nil
      end

      it 'updates attribute (after yield)' do
        expect(talkative.around_early_comment).to eql "I changed around creation (before yield)"
      end

      it 'does not persist updated attribute' do
        talkative.reload
        expect(talkative.around_late_comment).to be_nil
        expect(talkative.draft.reify.around_late_comment).to be_nil
      end
    end

    context 'after callback' do
      it 'updates attribute' do
        expect(talkative.after_comment).to eql "I changed after creation"
      end

      it 'does not persist updated attribute' do
        talkative.reload
        expect(talkative.after_comment).to be_nil
        expect(talkative.draft.reify.after_comment).to be_nil
      end
    end
  end


  describe 'draft_update' do
    before do
      talkative.draft_update
    end

    context 'before callback' do
      it 'updates attribute' do
        expect(talkative.before_comment).to eql "I changed before update"
      end

      it 'persists updated attribute to draft' do
        talkative.reload
        expect(talkative.draft.reify.before_comment).to eql "I changed before update"
      end
    end

    context 'around callback' do
      it 'updates attribute (before yield)' do
        expect(talkative.around_early_comment).to eql "I changed around update (before yield)"
      end

      it 'persists updated attribute to draft' do
        talkative.reload
        expect(talkative.draft.reify.around_late_comment).to be_nil
      end

      it 'updates attribute (after yield)' do
        expect(talkative.around_early_comment).to eql "I changed around update (before yield)"
      end

      it 'does not persist updated attribute' do
        talkative.reload
        expect(talkative.around_late_comment).to be_nil
        expect(talkative.draft.reify.around_late_comment).to be_nil
      end
    end

    context 'after callback' do
      it 'updates attribute' do
        expect(talkative.after_comment).to eql "I changed after update"
      end

      it 'does not persist updated attribute' do
        talkative.reload
        expect(talkative.after_comment).to be_nil
        expect(talkative.draft.reify.after_comment).to be_nil
      end
    end
  end


  describe 'draft_destroy' do
    before do
      talkative.draft_destroy
    end

    context 'before callback' do
      it 'updates attribute' do
        expect(talkative.before_comment).to eql "I changed before destroy"
      end

      it 'persists updated attribute to draft' do
        talkative.reload
        expect(talkative.draft.reify.before_comment).to eql "I changed before destroy"
      end
    end

    context 'around callback' do
      it 'updates attribute (before yield)' do
        expect(talkative.around_early_comment).to eql "I changed around destroy (before yield)"
      end

      it 'persists updated attribute to draft' do
        talkative.reload
        expect(talkative.draft.reify.around_late_comment).to be_nil
      end

      it 'updates attribute (after yield)' do
        expect(talkative.around_early_comment).to eql "I changed around destroy (before yield)"
      end

      it 'does not persist updated attribute' do
        talkative.reload
        expect(talkative.around_late_comment).to be_nil
        expect(talkative.draft.reify.around_late_comment).to be_nil
      end
    end

    context 'after callback' do
      it 'updates attribute' do
        expect(talkative.after_comment).to eql "I changed after destroy"
      end

      it 'does not persist updated attribute' do
        talkative.reload
        expect(talkative.after_comment).to be_nil
        expect(talkative.draft.reify.after_comment).to be_nil
      end
    end
  end
end