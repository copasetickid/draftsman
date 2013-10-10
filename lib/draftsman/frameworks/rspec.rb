if defined? RSpec
  require 'rspec/core'
  require 'rspec/matchers'

  RSpec.configure do |config|
    config.before(:each) do
      ::Draftsman.whodunnit  = nil
      ::Draftsman.controller_info = {} if defined?(::Rails) && defined?(::RSpec::Rails)
    end
  end

  RSpec::Matchers.define :be_draftable do
    # check to see if the model has `has_drafts` declared on it
    match { |actual| actual.kind_of?(::Draftsman::Model::InstanceMethods) }
  end
end
