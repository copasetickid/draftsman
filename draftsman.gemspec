$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'draftsman/version'

Gem::Specification.new do |s|
  s.name          = 'draftsman'
  s.version       = Draftsman::VERSION
  s.summary       = 'Create draft versions of your database records.'
  s.description   = "Stores draft versions of your ActiveRecord models' data in a single table or split up into separate tables. Works with Ruby on Rails and Sinatra."
  s.homepage      = 'https://github.com/liveeditor/draftsman'
  s.authors       = ['Chris Peters']
  s.email         = 'chris@minimalorange.com'
  s.license       = 'MIT'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_dependency 'activerecord', ['>= 3.0', '<= 5.0.0.rc1']

  s.add_development_dependency 'rake'
  s.add_development_dependency 'railties', ['>= 3.0', '< 5.0']
  s.add_development_dependency 'sinatra', '~> 1.0'
  s.add_development_dependency 'rspec-rails', '3.5.0.beta4'

  # JRuby support for the test ENV
  if defined?(JRUBY_VERSION)
    s.add_development_dependency 'activerecord-jdbcsqlite3-adapter', ['>= 1.3.0.rc1', '< 1.4']
  else
    s.add_development_dependency 'sqlite3', '~> 1.2'
  end
end
