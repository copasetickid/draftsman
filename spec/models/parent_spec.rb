require 'spec_helper'

describe Parent do
  let(:parent) { Parent.new(:name => 'Marge') }
  let(:child)  { Child.new(:name => 'Lisa', :parent => parent) }

  describe :publish! do
    context 'parent `create` draft with child `create` draft' do
      before do
        parent.draft_creation
        child.draft_creation
      end

      subject { parent.draft.publish! }

      its 'parent should be published' do
        subject
        parent.reload.should be_published
      end

      its 'parent should not be a draft' do
        subject
        parent.reload.should_not be_draft
      end

      its 'child should be a draft' do
        subject
        child.reload.should be_draft
      end

      its 'child should not be published' do
        subject
        child.reload.should_not be_published
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
        child.draft_destroy
        parent.draft_destroy
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

  describe :revert! do
    context 'parent `create` draft with child `create` draft' do
      before do
        parent.draft_creation
        child.draft_creation
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
        child.draft_destroy
        parent.draft_destroy
      end

      subject do
        parent.draft.revert!
        child.reload
        parent.reload
      end

      it { should be_persisted }
      it { should_not be_draft }
      it { should_not be_trashed }

      it "keeps the child's draft" do
        expect { subject }.to_not change(Draftsman::Draft.where(:item_type => 'Child'), :count)
      end

      it "deletes the parent's draft" do
        expect { subject }.to change(Draftsman::Draft.where(:item_type => 'Parent'), :count).by(-1)
      end

      its 'child should remain a draft' do
        subject
        child.should be_draft
      end

      its 'child should still be a `destroy` draft' do
        subject
        child.draft.reload.should be_destroy
      end

      its 'child should still be trashed' do
        subject
        child.should be_trashed
      end
    end
  end

  describe :draft_publication_dependencies do
    context 'parent `create` draft with child `create` draft' do
      before do
        parent.draft_creation
        child.draft_creation
      end

      subject { parent.draft }
      its(:draft_publication_dependencies) { should be_empty }
    end

    context 'parent `destroy` draft with child `destroy` draft' do
      before do
        child.save!
        parent.draft_destroy
        child.reload
      end

      subject { parent.draft }
      its(:draft_publication_dependencies) { should be_present }
      its(:draft_publication_dependencies) { should include child.draft }
    end
  end

  describe :draft_reversion_dependencies do
    context 'parent `create` draft with child `create` draft' do
      before do
        parent.draft_creation
        child.draft_creation
      end

      subject { parent.draft }
      its(:draft_reversion_dependencies) { should be_present }
      its(:draft_reversion_dependencies) { should include child.draft }
    end

    context 'parent `destroy` draft with child `destroy` draft' do
      before do
        child.save!
        parent.draft_destroy
        child.reload
      end

      subject { parent.draft }
      its(:draft_reversion_dependencies) { should be_empty }
    end
  end
end
