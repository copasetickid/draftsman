require 'spec_helper'

RSpec.describe OverriddenDraft, type: :model do
  context 'overridden via `draft_class_name` setting' do
    let(:vanilla) { Vanilla.new(name: 'Bob') }
    let!(:class_name_was) { Draftsman.draft_class_name }
    after { Draftsman.draft_class_name = class_name_was }

    before do
      Draftsman.draft_class_name = 'OverriddenDraft'

      class Vanilla <ActiveRecord::Base
        has_drafts
      end
    end

    describe '#draft.class.name' do
      it 'has an `OverriddenDraft` record as its draft' do
        vanilla.save_draft
        expect(vanilla.draft.class.name).to eql 'OverriddenDraft'
      end
    end
  end

  context 'with default `draft_class_name` setting' do
    let(:vanilla) { Vanilla.new(name: 'Bob') }

    before do
      class Vanilla < ActiveRecord::Base
        has_drafts
      end
    end

    describe '#draft.class.name' do
      it 'has the default `Draftsman::Draft` record as its draft' do
        vanilla.save_draft
        expect(vanilla.reload.draft.class.name).to eql 'Draftsman::Draft'
      end
    end
  end
end
