require 'spec_helper'

# Tests controller `info_for_draftsman` method
describe InformantsController, type: :controller do
  let(:trashable) { Trashable.create!(name: 'Bob') }

  describe 'create' do
    before { post :create }
    subject { Draftsman::Single::Draft.last }

    it 'records `ip` from custom `info_for_draftsman`' do
      expect(subject.ip).to eql '123.45.67.89'
    end

    it 'records `user_agent` from custom `info_for_draftsman`' do
      expect(subject.user_agent).to eql '007'
    end
  end

  describe 'update' do
    before { put :update, params: { id: trashable.id } }
    subject { Draftsman::Single::Draft.last }

    it 'records `ip` from custom `info_for_draftsman`' do
      expect(subject.ip).to eql '123.45.67.89'
    end

    it 'records `user_agent` from custom `info_for_draftsman`' do
      expect(subject.user_agent).to eql '007'
    end
  end

  describe 'destroy' do
    before { delete :destroy, params: { id: trashable.id } }
    subject { Draftsman::Single::Draft.last }

    it 'records `ip` from custom `info_for_draftsman`' do
      expect(subject.ip).to eql '123.45.67.89'
    end

    it 'records `user_agent` from custom `info_for_draftsman`' do
      expect(subject.user_agent).to eql '007'
    end
  end
end
