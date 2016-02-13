require 'spec_helper'

# A Talkative has a call to `has_drafts` and all nine callbacks defined:
#
# -  `before_draft_creation`
# -  `around_draft_creation`
# -  `after_draft_creation`
# -  `before_draft_update`
# -  `around_draft_update`
# -  `after_draft_update`
# -  `before_draft_destroy`
# -  `around_draft_destroy`
# -  `after_draft_destroy`
RSpec.describe Talkative do
  let(:talkative) { subject }

  describe '.draftable?' do
    it 'is draftable' do
      expect(talkative.class.draftable?).to eql true
    end
  end

  describe '#draft_creation' do
    before { talkative.draft_creation }

    describe '`before_draft_creation` callback' do
      it 'changes `before_comment` attribute' do
        expect(talkative.before_comment).to eql "I changed before creation"
      end

      it 'persists updated `before_comment` attribute to draft' do
        talkative.reload
        expect(talkative.draft.reify.before_comment).to eql "I changed before creation"
      end
    end

    describe 'around_draft_creation callback' do
      it 'changes `around_early_comment` attribute (before yield)' do
        expect(talkative.around_early_comment).to eql "I changed around creation (before yield)"
      end

      it 'persists updated `around_early_comment` attribute to draft' do
        talkative.reload
        expect(talkative.draft.reify.around_late_comment).to be_nil
      end

      it 'changes `around_late_comment` attribute (after yield)' do
        expect(talkative.around_late_comment).to eql "I changed around creation (after yield)"
      end

      it 'does not persist updated `around_late_comment` attribute' do
        talkative.reload
        expect(talkative.around_late_comment).to be_nil
      end

      it 'does not persist updated `around_late_comment` attribute to draft' do
        talkative.reload
        expect(talkative.draft.reify.around_late_comment).to be_nil
      end
    end

    describe '`after_draft_creation` callback' do
      it 'changes `after_comment` attribute' do
        expect(talkative.after_comment).to eql "I changed after creation"
      end

      it 'does not persist updated `after_comment` attribute' do
        talkative.reload
        expect(talkative.after_comment).to be_nil
      end

      it 'does not persist updated `after_comment` attribute to draft' do
        talkative.reload
        expect(talkative.draft.reify.after_comment).to be_nil
      end
    end
  end

  describe '#draft_update' do
    before do
      talkative.draft_creation
      talkative.draft_update
    end

    describe '`before_draft_update` callback' do
      it 'changes `before_comment` attribute' do
        expect(talkative.before_comment).to eql "I changed before update"
      end

      it 'persists updated `before_comment` attribute to draft' do
        talkative.reload
        expect(talkative.draft.reify.before_comment).to eql "I changed before update"
      end
    end

    describe '`around_draft_update` callback' do
      it 'changes `around_early_comment` attribute (before yield)' do
        expect(talkative.around_early_comment).to eql "I changed around update (before yield)"
      end

      it 'persists updated `around_early_comment` attribute' do
        talkative.reload
        expect(talkative.around_early_comment).to eql "I changed around update (before yield)"
      end

      it 'persists updated `around_early_comment` attribute to draft' do
        talkative.reload
        expect(talkative.draft.reify.around_early_comment).to eql "I changed around update (before yield)"
      end

      it 'changes `around_late_comment` attribute (after yield)' do
        expect(talkative.around_late_comment).to eql "I changed around update (after yield)"
      end

      it 'does not persist updated `around_late_comment` attribute' do
        talkative.reload
        expect(talkative.around_late_comment).to eql 'I changed around creation (after yield)'
      end

      it 'does not persist updated `around_late_comment` attribute to draft' do
        talkative.reload
        expect(talkative.draft.reify.around_late_comment).to eql 'I changed around creation (after yield)'
      end
    end

    describe 'after callback' do
      it 'changes `after_comment` attribute' do
        expect(talkative.after_comment).to eql "I changed after update"
      end

      it 'does not persist updated `after_comment` attribute' do
        talkative.reload
        expect(talkative.after_comment).to eql 'I changed after creation'
      end

      it 'does not persist updated `after_comment` attribute to draft' do
        talkative.reload
        expect(talkative.draft.reify.after_comment).to eql 'I changed after creation'
      end
    end
  end

  describe '#draft_destroy' do
    before do
      talkative.draft_creation
      talkative.draft_destroy
    end

    describe '`before_draft_destroy` callback' do
      it 'changes `before_comment` attribute' do
        expect(talkative.before_comment).to eql "I changed before destroy"
      end

      it 'does not persist updated `before_comment` attribute' do
        talkative.reload
        expect(talkative.before_comment).to eql "I changed before creation"
      end

      it 'does not persist updated `before_comment` attribute to draft' do
        talkative.reload
        expect(talkative.draft.reify.before_comment).to eql "I changed before creation"
      end
    end

    describe '`around_draft_destroy` callback' do
      it 'changes `around_early_comment` attribute (before yield)' do
        expect(talkative.around_early_comment).to eql "I changed around destroy (before yield)"
      end

      it 'does not persist `around_early_comment` attribute (before yield)' do
        expect(talkative.around_early_comment).to eql "I changed around destroy (before yield)"
      end

      it 'does not persist updated `around_early_comment` attribute to draft' do
        talkative.reload
        expect(talkative.draft.reify.around_early_comment).to eql "I changed around creation (before yield)"
      end

      it 'changes `around_late_comment` attribute (after yield)' do
        expect(talkative.around_late_comment).to eql "I changed around destroy (after yield)"
      end

      it 'does not persist updated `around_late_comment` attribute' do
        talkative.reload
        expect(talkative.around_late_comment).to be_nil
      end

      it 'does not persist updated `around_late_comment` attribute to draft' do
        talkative.reload
        expect(talkative.draft.reify.around_late_comment).to be_nil
      end
    end

    describe '`after_draft_destroy` callback' do
      it 'changes `before_comment` attribute' do
        expect(talkative.before_comment).to eql "I changed before destroy"
      end

      it 'does not persist updated `before_comment` attribute' do
        talkative.reload
        expect(talkative.before_comment).to eql 'I changed before creation'
      end

      it 'does not persist updated `before_comment` attribute to draft' do
        talkative.reload
        expect(talkative.draft.reify.before_comment).to eql 'I changed before creation'
      end

      it 'changes `after_comment` attribute' do
        expect(talkative.after_comment).to eql "I changed after destroy"
      end

      it 'does not persist updated `after_comment` attribute' do
        talkative.reload
        expect(talkative.after_comment).to be_nil
      end

      it 'does not persist updated `after_comment` attribute to draft' do
        talkative.reload
        expect(talkative.draft.reify.after_comment).to be_nil
      end
    end
  end
end
