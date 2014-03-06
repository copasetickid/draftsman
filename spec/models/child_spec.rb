require 'spec_helper'

describe Child do
  let(:parent) { Parent.new(:name => 'Marge') }
  let(:child)  { Child.new(:name => 'Lisa', :parent => parent) }

  describe :publish! do
    context 'parent `create` draft with child `create` draft' do
      before do
        parent.draft_creation
        child.draft_creation
      end

      subject { child.draft.publish! }

      its 'child should not be a draft' do
        subject
        child.reload.should_not be_draft
      end

      its 'child should be published' do
        subject
        child.reload.should be_published
      end

      its 'parent should be published' do
        subject
        parent.reload.should be_published
      end

      its 'parent should not be a draft' do
        subject
        parent.reload.should_not be_draft
      end

      it 'destroys both drafts' do
        expect { subject }.to change(Draftsman::Draft, :count).by(-2)
      end

      it "destroys the child's draft" do
        expect { subject }.to change(Draftsman::Draft.where(:item_type => 'Child'), :count).by(-1)
      end

      it "destroys the parent's draft" do
        expect { subject }.to change(Draftsman::Draft.where(:item_type => 'Parent'), :count).by(-1)
      end
    end

    context 'parent `destroy` draft with child `destroy` draft' do
      before do
        parent.save!
        child.save!
        child.draft_destroy
        parent.draft_destroy
      end

      subject { child.draft.publish! }

      it 'destroys the child' do
        expect { subject }.to change(Child, :count).by(-1)
      end

      it 'keeps the parent' do
        expect { subject }.to_not change(Parent, :count)
      end

      it 'destroys 1 draft' do
        expect { subject }.to change(Draftsman::Draft, :count).by(-1)
      end

      it "destroys the child's draft" do
        expect { subject }.to change(Draftsman::Draft.where(:item_type => 'Child'), :count).by(-1)
      end
    end
  end

  describe :revert! do
    context 'parent `create` draft with child `create` draft' do
      before do
        parent.draft_creation
        child.draft_creation
      end

      subject { child.draft.revert! }

      it 'destroys the parent' do
        expect { subject }.to_not change(Parent, :count).by(-1)
      end

      it 'destroys the child' do
        expect { subject }.to change(Child, :count).by(-1)
      end

      it 'only destroys 1 draft overall' do
        expect { subject }.to change(Draftsman::Draft, :count).by(-1)
      end

      it 'destroys the child draft' do
        expect { subject }.to change(Draftsman::Draft.where(:item_type => 'Child'), :count).by(-1)
      end
    end

    context 'parent `destroy` draft with child `destroy` draft' do
      before do
        parent.save!
        child.save!
        child.draft_destroy
        parent.draft_destroy
      end

      subject do
        child.draft.revert!
        parent.reload
        child.reload 
      end

      it { should be_persisted }
      it { should_not be_trashed }
      it { should_not be_draft }

      it 'deletes both drafts' do
        expect { subject }.to change(Draftsman::Draft, :count).by(-2)
      end

      it "deletes the parent's draft" do
        expect { subject }.to change(Draftsman::Draft.where(:item_type => 'Parent'), :count).by(-1)
      end

      it "deletes the child's draft" do
        expect { subject }.to change(Draftsman::Draft.where(:item_type => 'Child'), :count).by(-1)
      end

      its 'parent should not be trashed anymore' do
        subject
        parent.should_not be_trashed
      end

      its 'child should not be a draft anymore' do
        subject
        child.should_not be_draft
      end
    end
  end

  describe :draft_publication_dependencies do
    context 'parent `create` draft with child `create` draft' do
      before do
        parent.draft_creation
        child.draft_creation
      end

      subject { child.draft }
      its(:draft_publication_dependencies) { should_not be_empty }
      its(:draft_publication_dependencies) { should include parent.draft }
    end

    context 'parent `create` draft with child `update` draft' do
      before do
        parent.draft_creation
        child.save!
        child.name = 'Heather'
        child.draft_update
      end

      subject { child.draft }
      its(:draft_publication_dependencies) { should_not be_empty }
      its(:draft_publication_dependencies) { should include parent.draft }
    end

    context 'parent `create` draft with child `update` draft pointing to new parent' do
      let(:new_parent) { Parent.new(:name => 'Patty') }
      before do
        parent.draft_creation
        child.save!
        new_parent.draft_creation
        child.parent = new_parent
        child.draft_update
      end

      subject { child.draft }
      its(:draft_publication_dependencies) { should_not be_empty }
      its(:draft_publication_dependencies) { should_not include parent.draft}
      its(:draft_publication_dependencies) { should include new_parent.draft }
    end

    context 'parent `destroy` draft with child `destroy` draft' do
      before do
        child.save!
        parent.draft_destroy
        child.reload
      end

      subject { child.draft }
      its(:draft_publication_dependencies) { should be_empty }
    end
  end

  describe :draft_reversion_dependencies do
    context 'parent `create` draft with child `create` draft' do
      before do
        parent.draft_creation
        child.draft_creation
      end

      subject { child.draft }
      its(:draft_reversion_dependencies) { should be_empty }
    end

    context 'parent `destroy` draft with child `destroy` draft' do
      before do
        child.save!
        parent.draft_destroy
        child.reload
      end

      subject { child.draft }
      its(:draft_reversion_dependencies) { should be_present }
      its(:draft_reversion_dependencies) { should include parent.draft }
    end
  end
end
