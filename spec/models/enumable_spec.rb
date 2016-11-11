require 'spec_helper'

RSpec.describe Enumable, type: :model do
  let(:enumable) { Enumable.new(status: :active) }

  describe '#draft' do
    describe '#reify' do
      before { enumable.save_draft }

      it 'does not raise an exception' do
        expect { enumable.draft.reify }.to_not raise_error
      end
    end
  end
end
