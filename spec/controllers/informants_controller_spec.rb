require 'spec_helper'

# Tests controller `info_for_draftsman` method
describe InformantsController do
  let(:trashable) { Trashable.create!(:name => 'Bob') }

  describe :create do
    before { post :create }
    subject { Draftsman::Draft.last }
    its(:ip) { should eql '123.45.67.89' }
    its(:user_agent) { should eql '007' }
  end

  describe :update do
    before { put :update, :id => trashable.id }
    subject { Draftsman::Draft.last }
    its(:ip) { should eql '123.45.67.89' }
    its(:user_agent) { should eql '007' }
  end

  describe :destroy do
    before { delete :destroy, :id => trashable.id }
    subject { Draftsman::Draft.last }
    its(:ip) { should eql '123.45.67.89' }
    its(:user_agent) { should eql '007' }
  end
end
