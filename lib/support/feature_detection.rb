# Returns whether migrations need to be versioned.
def activerecord_migrations_versioned?
  ActiveRecord::VERSION::MAJOR >= 5
end
