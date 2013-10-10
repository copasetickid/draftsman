$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'draftsman/version'

Gem::Specification.new do |s|
  s.name          = 'draftsman'
  s.version       = Draftsman::VERSION
  s.summary       = 'Add drafts to ActiveRecord models.'
  s.description   = s.summary
  s.homepage      = 'https://github.com/live-editor/draftsman'
  s.authors       = ['Chris Peters']
  s.email         = 'chris@clearcrystalmedia.com'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_dependency 'activerecord', ['>= 3.0', '< 5.0']

  s.add_development_dependency 'capybara'
  s.add_development_dependency 'jquery-rails'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rails', '>= 3.2'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'shoulda-matchers'
  s.add_development_dependency 'sqlite3'

  # JRuby support for the test ENV
  unless defined?(JRUBY_VERSION)
    s.add_development_dependency 'sqlite3', '~> 1.2'
  else
    s.add_development_dependency 'activerecord-jdbcsqlite3-adapter', ['>= 1.3.0.rc1', '< 1.4']
  end
end
