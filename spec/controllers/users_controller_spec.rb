require 'spec_helper'

describe UsersController, type: :controller do
  let(:trashable) { Trashable.create!(name: 'Bob') }

  describe 'create' do
    before { post :create }
    subject { Draftsman::Draft.last }

    it 'records user name via `user_for_draftsman`' do
      expect(subject.whodunnit).to eql 'A User'
    end
  end

  describe 'update' do
    before { put :update, id: trashable.id }
    subject { return Draftsman::Draft.last }

    it 'records user name via `user_for_draftsman`' do
      expect(subject.whodunnit).to eql 'A User'
    end
  end

  describe 'destroy' do
    before { delete :destroy, id: trashable.id }
    subject { return Draftsman::Draft.last }

    it 'records user name via `user_for_draftsman`' do
      expect(subject.whodunnit).to eql 'A User'
    end
  end
end
