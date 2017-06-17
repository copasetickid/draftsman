require 'spec_helper'

describe UsersController, type: :controller do
  let(:trashable) { Trashable.create!(name: 'Bob') }

  describe 'create' do
    before { post :create }
    subject { Draftsman::Single::Draft.last }

    it 'records user name via `user_for_draftsman`' do
      expect(subject.whodunnit).to eql 'A User'
    end
  end

  describe 'update' do
    before { put :update, params: { id: trashable.id } }
    subject { return Draftsman::Single::Draft.last }

    it 'records user name via `user_for_draftsman`' do
      expect(subject.whodunnit).to eql 'A User'
    end
  end

  describe 'destroy' do
    before { delete :destroy, params: { id: trashable.id } }
    subject { return Draftsman::Single::Draft.last }

    it 'records user name via `user_for_draftsman`' do
      expect(subject.whodunnit).to eql 'A User'
    end
  end
end
