require 'rails/generators'
require 'rails/generators/migration'
require 'rails/generators/active_record'

module Draftsman
  class InstallGenerator < ::Rails::Generators::Base
    include ::Rails::Generators::Migration

    desc 'Generates (but does not run) a migration to add a drafts table.'
    source_root File.expand_path('../templates', __FILE__)
    class_option :skip_initializer, :type => :boolean, :default => false, :desc => 'Skip generation of the boilerplate initializer at `config/initializers/draftsman.rb`.'
    class_option :with_changes, :type => :boolean, :default => false, :desc => 'Store changeset (diff) with each draft'

    def create_migration_file
      migration_template 'create_drafts.rb', 'db/migrate/create_drafts.rb'
      migration_template 'add_object_changes_column_to_drafts.rb', 'db/migrate/add_object_changes_column_to_drafts.rb' if options.with_changes?
    end

    def self.next_migration_number(dirname)
      ActiveRecord::Generators::Base.next_migration_number(dirname)
    end

    def copy_config
      template 'config/initializers/draftsman.rb' unless options.skip_initializer?
    end
  end
end
