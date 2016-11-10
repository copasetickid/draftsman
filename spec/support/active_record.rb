require "rake"

if ENV['TRAVIS']
  Rake::Task["db:schema:load"].invoke
end
