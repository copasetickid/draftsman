require 'spec_helper'
require 'support/feature_detection'

# Tests the automatic usage of `current_user` as the `whodunnit` attribute on the draft object
describe WhodunnitsController, type: :controller do
  let(:trashable) { Trashable.create!(name: 'Bob') }

  describe 'create' do
    it 'records `current_user` via `user_for_draftsman' do
      post :create
      expect(Draftsman::Draft.last.whodunnit).to eql '153'
    end
  end

  describe 'update' do
    it 'records `current_user` via `user_for_draftsman' do
      if request_test_helpers_require_keyword_args?
        put :update, params: { id: trashable.id }
      else
        put :update, id: trashable.id
      end

      expect(Draftsman::Draft.last.whodunnit).to eql '153'
    end
  end

  describe 'destroy' do
    it 'records `current_user` via `user_for_draftsman' do
      if request_test_helpers_require_keyword_args?
        delete :destroy, params: { id: trashable.id }
      else
        delete :destroy, id: trashable.id
      end

      expect(Draftsman::Draft.last.whodunnit).to eql '153'
    end
  end
end
