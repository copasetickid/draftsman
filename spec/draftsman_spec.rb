require 'spec_helper.rb'

describe ::Draftsman do
  describe 'Sanity Test' do
    it { should be_a Module }
  end

  describe :whodunnit do
    before(:all) { ::Draftsman.whodunnit = 'foobar' }
    # Clears out `source` before each test
    its(:whodunnit) { should be_nil }
  end

  describe :controller_info do
    before(:all) { ::Draftsman.controller_info = { foo: 'bar' } }
    # Clears out `controller_info` before each test
    its(:controller_info) { should == {} }
  end
end
