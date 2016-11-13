require 'spec_helper.rb'

describe ::Draftsman do
  it 'passes our sanity test' do
    expect(::Draftsman).to be_a Module
  end

  describe '.whodunnit' do
    before(:all) { ::Draftsman.whodunnit = :foobar }

    it 'clears out `whodunnit` before each test' do
      expect(::Draftsman.whodunnit).to be_nil
    end
  end

  describe '.controller_info' do
    before(:all) { ::Draftsman.controller_info = { foo: :bar } }

    it 'clears out `controller_info` before each test' do
      expect(::Draftsman.controller_info).to eql Hash.new
    end
  end
end
