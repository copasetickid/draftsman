require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'yaml'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

desc "Run spec with Docker"
task :build, [:version] do |t, args|
    args.with_defaults(:version => RUBY_VERSION)
    system("docker build --build-arg VERSION=#{args.version} -t draftsman-#{args.version} .")
end

desc "Run spec with Docker"
task :test, [:version] do |t, args|
    args.with_defaults(:version => RUBY_VERSION)
    if %x[docker images -q draftsman-#{args.version}].empty?
        Rake::Task[:build].reenable
        Rake::Task[:build].invoke(args.version)
    end
    system("docker run draftsman-#{args.version}")
end

desc "Run spec with Docker"
task :test_all do
    travis = YAML.load_file('.travis.yml')
    for version in travis['rvm'] do
        Rake::Task[:test].reenable
        Rake::Task[:test].invoke(version)
    end
end
