require 'spec_helper'
require 'support/feature_detection'

# Tests controller `info_for_draftsman` method
describe InformantsController, type: :controller do
  let(:trashable) { Trashable.create!(name: 'Bob') }

  describe 'create' do
    it 'records `ip` from custom `info_for_draftsman`' do
      post :create
      expect(Draftsman::Draft.last.ip).to eql '123.45.67.89'
    end

    it 'records `user_agent` from custom `info_for_draftsman`' do
      post :create
      expect(Draftsman::Draft.last.user_agent).to eql '007'
    end
  end

  describe 'update' do
    it 'records `ip` from custom `info_for_draftsman`' do
      if request_test_helpers_require_keyword_args?
        put :update, params: { id: trashable.id }
      else
        put :update, id: trashable.id
      end

      expect(Draftsman::Draft.last.ip).to eql '123.45.67.89'
    end

    it 'records `user_agent` from custom `info_for_draftsman`' do
      if request_test_helpers_require_keyword_args?
        put :update, params: { id: trashable.id }
      else
        put :update, id: trashable.id
      end

      expect(Draftsman::Draft.last.user_agent).to eql '007'
    end
  end

  describe 'destroy' do
    it 'records `ip` from custom `info_for_draftsman`' do
      if request_test_helpers_require_keyword_args?
        delete :destroy, params: { id: trashable.id }
      else
        delete :destroy, id: trashable.id
      end

      expect(Draftsman::Draft.last.ip).to eql '123.45.67.89'
    end

    it 'records `user_agent` from custom `info_for_draftsman`' do
      if request_test_helpers_require_keyword_args?
        delete :destroy, params: { id: trashable.id }
      else
        delete :destroy, id: trashable.id
      end

      expect(Draftsman::Draft.last.user_agent).to eql '007'
    end
  end
end
