require 'spec_helper.rb'

describe ::Draftsman do
  subject { ::Draftsman }

  it 'passes our sanity test' do
    expect(subject).to be_a Module
  end

  describe :whodunnit do
    before(:all) { ::Draftsman.whodunnit = 'foobar' }

    it 'clears out `whodunnit` before each test' do
      expect(subject.whodunnit).to be_nil
    end
  end

  describe :controller_info do
    before(:all) { ::Draftsman.controller_info = { foo: 'bar' } }

    it 'clears out `controller_info` before each test' do
      expect(subject.controller_info).to eql Hash.new
    end
  end
end
