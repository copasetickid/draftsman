require 'spec_helper'

# A Talkative has a call to `has_drafts` and all six callbacks defined:
#
# -  `before_save_draft`
# -  `around_save_draft`
# -  `after_save_draft`
# -  `before_draft_destruction`
# -  `around_draft_destruction`
# -  `after_draft_destruction`
RSpec.describe Talkative, type: :model do
  let(:talkative) { subject }

  describe '.draftable?' do
    it 'is draftable' do
      expect(talkative.class.draftable?).to eql true
    end
  end

  describe '#save_draft' do
    context 'on create' do
      before { talkative.save_draft }

      describe '`before_save_draft` callback' do
        it 'changes `before_comment` attribute' do
          expect(talkative.before_comment).to eql 'I changed before save'
        end

        it 'persists updated `before_comment` attribute to draft' do
          talkative.reload
          expect(talkative.draft.reify.before_comment).to eql 'I changed before save'
        end
      end

      describe '`around_save_draft` callback' do
        it 'changes `around_early_comment` attribute (before yield)' do
          expect(talkative.around_early_comment).to eql 'I changed around save (before yield)'
        end

        it 'does not persist updated `around_early_comment` attribute to draft' do
          talkative.reload
          expect(talkative.draft.reify.around_late_comment).to be_nil
        end

        it 'changes `around_late_comment` attribute (after yield)' do
          expect(talkative.around_late_comment).to eql 'I changed around save (after yield)'
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

      describe '`after_save_draft` callback' do
        it 'changes `after_comment` attribute' do
          expect(talkative.after_comment).to eql 'I changed after save'
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

    context 'on update' do
      before do
        talkative.save
        talkative.save_draft
      end

      describe '`before_save_draft` callback' do
        it 'changes `before_comment` attribute' do
          expect(talkative.before_comment).to eql 'I changed before save'
        end

        it 'persists updated `before_comment` attribute to draft' do
          talkative.reload
          expect(talkative.draft.reify.before_comment).to eql 'I changed before save'
        end
      end

      describe '`around_save_draft` callback' do
        it 'changes `around_early_comment` attribute (before yield)' do
          expect(talkative.around_early_comment).to eql 'I changed around save (before yield)'
        end

        it 'does not persist updated `around_early_comment` attribute' do
          talkative.reload
          expect(talkative.around_early_comment).to be_nil
        end

        it 'persists updated `around_early_comment` attribute to draft' do
          talkative.reload
          expect(talkative.draft.reify.around_early_comment).to eql 'I changed around save (before yield)'
        end

        it 'changes `around_late_comment` attribute (after yield)' do
          expect(talkative.around_late_comment).to eql 'I changed around save (after yield)'
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

      describe 'after callback' do
        it 'changes `after_comment` attribute' do
          expect(talkative.after_comment).to eql 'I changed after save'
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

  describe '#draft_destruction' do
    before do
      talkative.save_draft
      talkative.draft_destruction
    end

    describe '`before_draft_destruction` callback' do
      it 'changes `before_comment` attribute' do
        expect(talkative.before_comment).to eql 'I changed before destroy'
      end

      it 'does not persist updated `before_comment` attribute' do
        talkative.reload
        expect(talkative.before_comment).to eql 'I changed before save'
      end

      it 'does not persist updated `before_comment` attribute to draft' do
        talkative.reload
        expect(talkative.draft.reify.before_comment).to eql 'I changed before save'
      end
    end

    describe '`around_draft_destruction` callback' do
      it 'changes `around_early_comment` attribute (before yield)' do
        expect(talkative.around_early_comment).to eql 'I changed around destroy (before yield)'
      end

      it 'does not persist `around_early_comment` attribute (before yield)' do
        expect(talkative.around_early_comment).to eql 'I changed around destroy (before yield)'
      end

      it 'does not persist updated `around_early_comment` attribute to draft' do
        talkative.reload
        expect(talkative.draft.reify.around_early_comment).to eql 'I changed around save (before yield)'
      end

      it 'changes `around_late_comment` attribute (after yield)' do
        expect(talkative.around_late_comment).to eql 'I changed around destroy (after yield)'
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

    describe '`after_draft_destruction` callback' do
      it 'changes `before_comment` attribute' do
        expect(talkative.before_comment).to eql 'I changed before destroy'
      end

      it 'does not persist updated `before_comment` attribute' do
        talkative.reload
        expect(talkative.before_comment).to eql 'I changed before save'
      end

      it 'does not persist updated `before_comment` attribute to draft' do
        talkative.reload
        expect(talkative.draft.reify.before_comment).to eql 'I changed before save'
      end

      it 'changes `after_comment` attribute' do
        expect(talkative.after_comment).to eql 'I changed after destroy'
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
