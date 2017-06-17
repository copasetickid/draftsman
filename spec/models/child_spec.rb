require 'spec_helper'

RSpec.describe Child, type: :model do
  let(:parent) { Parent.new(name: 'Marge') }
  let(:child)  { Child.new(name: 'Lisa', parent: parent) }

  describe '#publish!' do
    context 'parent `create` draft with child `create` draft' do
      before do
        parent.save_draft
        child.save_draft
      end

      subject { child.draft.publish! }

      it "destroys the child's draft" do
        subject
        expect(child.reload).to_not be_draft
      end

      it 'publishes the child' do
        subject
        expect(child.reload).to be_published
      end

      it 'publishes the parent' do
        subject
        expect(parent.reload).to be_published
      end

      it "destroys the parent's draft" do
        subject
        expect(parent.reload).to_not be_draft
      end

      it 'destroys 2 drafts overall' do
        expect { subject }.to change(Draftsman::Single::Draft, :count).by(-2)
      end

      it "destroys the child's draft" do
        expect { subject }.to change(Draftsman::Single::Draft.where(:item_type => 'Child'), :count).by(-1)
      end

      it "destroys the parent's draft" do
        expect { subject }.to change(Draftsman::Single::Draft.where(:item_type => 'Parent'), :count).by(-1)
      end
    end

    context 'parent `destroy` draft with child `destroy` draft' do
      before do
        parent.save!
        child.save!
        child.draft_destruction
        parent.draft_destruction
      end

      subject { child.draft.publish! }

      it 'destroys the child' do
        expect { subject }.to change(Child, :count).by(-1)
      end

      it 'keeps the parent' do
        expect { subject }.to_not change(Parent, :count)
      end

      it 'destroys 1 draft overall' do
        expect { subject }.to change(Draftsman::Single::Draft, :count).by(-1)
      end

      it "destroys the child's draft" do
        expect { subject }.to change(Draftsman::Single::Draft.where(:item_type => 'Child'), :count).by(-1)
      end
    end
  end

  describe '#revert!' do
    context 'parent `create` draft with child `create` draft' do
      before do
        parent.save_draft
        child.save_draft
      end

      subject { child.draft.revert! }

      it 'destroys the parent' do
        expect { subject }.to_not change(Parent, :count)
      end

      it 'destroys the child' do
        expect { subject }.to change(Child, :count).by(-1)
      end

      it 'destroys 1 draft overall' do
        expect { subject }.to change(Draftsman::Single::Draft, :count).by(-1)
      end

      it "destroys the child's draft" do
        expect { subject }.to change(Draftsman::Single::Draft.where(:item_type => 'Child'), :count).by(-1)
      end
    end

    context 'parent `destroy` draft with child `destroy` draft' do
      before do
        parent.save!
        child.save!
        child.draft_destruction
        parent.draft_destruction
      end

      subject do
        child.draft.revert!
        parent.reload
        child.reload
      end

      it 'does not persist the child' do
        expect(subject.persisted?).to eql true
      end

      it 'removes the child from the trash' do
        expect(subject.trashed?).to eql false
      end

      it "destroys the child's draft" do
        expect(subject.draft?).to eql false
      end

      it 'destroys 2 drafts overall' do
        expect { subject }.to change(Draftsman::Single::Draft, :count).by(-2)
      end

      it "destroys the parent's draft" do
        expect { subject }.to change(Draftsman::Single::Draft.where(:item_type => 'Parent'), :count).by(-1)
      end

      it "destroys the child's draft" do
        expect { subject }.to change(Draftsman::Single::Draft.where(:item_type => 'Child'), :count).by(-1)
      end

      it 'removes the parent from the trash' do
        subject
        expect(parent).to_not be_trashed
      end

      it "destroys the child's draft" do
        subject
        expect(child).to_not be_draft
      end
    end
  end

  describe '#draft_publication_dependencies' do
    context 'parent `create` draft with child `create` draft' do
      before do
        parent.save_draft
        child.save_draft
      end

      subject { child.draft }

      it "creates publication dependencies for the child's draft" do
        expect(subject.draft_publication_dependencies).to_not be_empty
      end

      it "includes the parent as a publication dependency for the child's draft" do
        expect(subject.draft_publication_dependencies).to include parent.draft
      end
    end

    context 'parent `create` draft with child `update` draft' do
      before do
        parent.save_draft
        child.save!
        child.name = 'Heather'
        child.save_draft
      end

      subject { child.draft }

      it "creates publication dependencies for the child's draft" do
        expect(subject.draft_publication_dependencies).to_not be_empty
      end

      it "includes the parent as a publication dependency for the child's draft" do
        expect(subject.draft_publication_dependencies).to include parent.draft
      end
    end

    context 'parent `create` draft with child `update` draft pointing to new parent' do
      let(:new_parent) { Parent.new(:name => 'Patty') }

      before do
        parent.save_draft
        child.save!
        new_parent.save_draft
        child.parent = new_parent
        child.save_draft
      end

      subject { child.draft }

      it "creates publication dependencies for the child's draft" do
        expect(subject.draft_publication_dependencies).to_not be_empty
      end

      it "removes the old parent as a publication dependency for the child's draft" do
        expect(subject.draft_publication_dependencies).to_not include parent.draft
      end

      it "includes the new parent as a publication dependency for the child's draft" do
        expect(subject.draft_publication_dependencies).to include new_parent.draft
      end
    end

    context 'parent `destroy` draft with child `destroy` draft' do
      before do
        child.save!
        parent.draft_destruction
        child.reload
      end

      subject { child.draft }

      it "has no publication dependencies for the child's draft" do
        expect(subject.draft_publication_dependencies).to be_empty
      end
    end
  end

  describe '#draft_reversion_dependencies' do
    context 'parent `create` draft with child `create` draft' do
      before do
        parent.save_draft
        child.save_draft
      end

      subject { child.draft }

      it "has no reversion dependencies for the child's draft" do
        expect(subject.draft_reversion_dependencies).to be_empty
      end
    end

    context 'parent `destroy` draft with child `destroy` draft' do
      before do
        child.save!
        parent.draft_destruction
        child.reload
      end

      subject { child.draft }

      it "creates reversion dependencies for the child's draft" do
        expect(subject.draft_reversion_dependencies).to be_present
      end

      it "includes the parent as a reversion dependency for the child's draft" do
        expect(subject.draft_reversion_dependencies).to include parent.draft
      end
    end
  end
end
