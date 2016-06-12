require 'spec_helper'

# Tests the automatic usage of `current_user` as the `whodunnit` attribute on the draft object
describe WhodunnitsController, type: :controller do
  let(:trashable) { Trashable.create!(name: 'Bob') }

  describe 'create' do
    before { post :create }
    subject { Draftsman::Draft.last }

    it 'records `current_user` via `user_for_draftsman' do
      expect(subject.whodunnit).to eql '153'
    end
  end

  describe 'update' do
    before { put :update, id: trashable.id }
    subject { Draftsman::Draft.last }

    it 'records `current_user` via `user_for_draftsman' do
      expect(subject.whodunnit).to eql '153'
    end
  end

  describe 'destroy' do
    before { delete :destroy, id: trashable.id }
    subject { Draftsman::Draft.last }

    it 'records `current_user` via `user_for_draftsman' do
      expect(subject.whodunnit).to eql '153'
    end
  end
end
