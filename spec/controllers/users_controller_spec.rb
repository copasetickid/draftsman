require 'spec_helper'

describe UsersController do
  let(:trashable) { Trashable.create!(:name => 'Bob') }

  describe :create do
    before { post :create }
    subject { Draftsman::Draft.last }
    its(:whodunnit) { should eql 'A User' }
  end

  describe :update do
    before { put :update, :id => trashable.id }
    subject { return Draftsman::Draft.last }
    its(:whodunnit) { should eql 'A User' }
  end

  describe :destroy do
    before { delete :destroy, :id => trashable.id }
    subject { return Draftsman::Draft.last }
    its(:whodunnit) { should eql 'A User' }
  end
end
