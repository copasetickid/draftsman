require 'spec_helper'
require 'support/feature_detection'

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
    it 'records user name via `user_for_draftsman`' do
      if request_test_helpers_require_keyword_args?
        put :update, params: { id: trashable.id }
      else
        put :update, id: trashable.id
      end

      expect(Draftsman::Draft.last.whodunnit).to eql 'A User'
    end
  end

  describe 'destroy' do
    it 'records user name via `user_for_draftsman`' do
      if request_test_helpers_require_keyword_args?
        delete :destroy, params: { id: trashable.id }
      else
        delete :destroy, id: trashable.id
      end

      expect(Draftsman::Draft.last.whodunnit).to eql 'A User'
    end
  end
end
