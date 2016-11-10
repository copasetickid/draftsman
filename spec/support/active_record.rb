require "rake"

if ENV['TRAVIS']
  Rake::Task["db:create"].invoke
  Rake::Task["db:schema:load"].invoke
end
