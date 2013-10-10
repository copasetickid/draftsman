if defined? World
  # before hook for Cucumber
  before do
    ::Draftsman.whodunnit  = nil
    ::Draftsman.controller_info = {} if defined? ::Rails
  end
end
