require 'spec_helper'

describe Parent do
  let(:parent) { Parent.new(:name => 'Marge') }
  let(:child)  { Child.new(:name => 'Lisa', :parent => parent) }

  describe 'publish!' do
    context 'parent `create` draft with child `create` draft' do
      before do
        parent.save_draft
        child.save_draft
      end

      subject { parent.draft.publish! }

      it 'publishes the parent' do
        subject
        expect(parent.reload.published?).to eql true
      end

      it "removes the parent's draft" do
        subject
        expect(parent.reload.draft?).to eql false
      end

      it 'keeps the child as a draft' do
        subject
        expect(child.reload.draft?).to eql true
      end

      it 'does not publish the child' do
        subject
        expect(child.reload.published?).to eql false
      end

      it 'destroys 1 draft' do
        expect { subject }.to change(Draftsman::Draft, :count).by(-1)
      end

      it "destroys the parent's draft" do
        expect { subject }.to change(Draftsman::Draft.where(:item_type => 'Parent'), :count).by(-1)
      end
    end

    context 'parent `destroy` draft with child `destroy` draft' do
      before do
        child.save!
        child.draft_destruction
        parent.draft_destruction
      end

      subject { parent.draft.publish! }

      it 'destroys the parent' do
        expect { subject }.to change(Parent, :count).by(-1)
      end

      it 'destroys the child' do
        expect { subject }.to change(Child, :count).by(-1)
      end

      it 'destroys 2 drafts' do
        expect { subject }.to change(Draftsman::Draft, :count).by(-2)
      end
    end
  end

  describe 'revert!' do
    context 'parent `create` draft with child `create` draft' do
      before do
        parent.save_draft
        child.save_draft
      end

      subject { parent.draft.revert! }

      it 'destroys the parent' do
        expect { subject }.to change(Parent, :count).by(-1)
      end

      it 'destroys the child' do
        expect { subject }.to change(Child, :count).by(-1)
      end

      it 'destroys both drafts' do
        expect { subject }.to change(Draftsman::Draft, :count).by(-2)
      end
    end

    context 'parent `destroy` draft with child `destroy` draft' do
      before do
        child.save!
        child.draft_destruction
        parent.draft_destruction
      end

      subject do
        parent.draft.revert!
        child.reload
        parent.reload
      end

      it 'is persisted to the database' do
        expect(subject).to be_persisted
      end

      it 'is no longer a draft' do
        expect(subject.draft?).to eql false
      end

      it 'is no longer trashed' do
        expect(subject.trashed?).to eql false
      end

      it "keeps the child's draft" do
        expect { subject }.to_not change(Draftsman::Draft.where(:item_type => 'Child'), :count)
      end

      it "deletes the parent's draft" do
        expect { subject }.to change(Draftsman::Draft.where(:item_type => 'Parent'), :count).by(-1)
      end

      it "keeps the child's draft" do
        subject
        expect(child.draft?).to eql true
      end

      it "keeps the child as a `destroy` draft" do
        subject
        expect(child.draft.reload.destroy?).to eql true
      end

      it 'keeps the child trashed' do
        subject
        expect(child.trashed?).to eql true
      end
    end
  end

  describe 'draft_publication_dependencies' do
    context 'parent `create` draft with child `create` draft' do
      before do
        parent.save_draft
        child.save_draft
      end

      subject { parent.draft }

      it 'does not have publication dependencies' do
        expect(subject.draft_publication_dependencies).to be_empty
      end
    end

    context 'parent `update` draft with child `create` draft' do
      before do
        parent.save!
        parent.name = 'Selma'
        parent.save_draft
        child.save_draft
      end

      subject { parent.draft }

      it 'does not have publication dependencies' do
        expect(subject.draft_publication_dependencies).to be_empty
      end
    end

    context 'parent `destroy` draft with child `destroy` draft' do
      before do
        child.save!
        parent.draft_destruction
        child.reload
      end

      subject { parent.draft }

      it 'has publication dependencies' do
        expect(subject.draft_publication_dependencies).to be_present
      end

      it "has the child's draft as a publication dependency" do
        expect(subject.draft_publication_dependencies).to include child.draft
      end
    end
  end

  describe 'draft_reversion_dependencies' do
    context 'parent `create` draft with child `create` draft' do
      before do
        parent.save_draft
        child.save_draft
      end

      subject { parent.draft }

      it 'has reversion dependencies' do
        expect(subject.draft_reversion_dependencies).to be_present
      end

      it "has the child's draft as a reversion dependency" do
        expect(subject.draft_reversion_dependencies).to include child.draft
      end
    end

    context 'parent `destroy` draft with child `destroy` draft' do
      before do
        child.save!
        parent.draft_destruction
        child.reload
      end

      subject { parent.draft }

      it 'does not have reversion dependencies' do
        expect(subject.draft_reversion_dependencies).to be_empty
      end
    end
  end
end
