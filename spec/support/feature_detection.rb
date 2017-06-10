# Returns whether or not Rails test helpers recommend or require keyword
# arguments for controller/request helpers.
def request_test_helpers_require_keyword_args?
  ActiveRecord::VERSION::STRING.to_f >= 5.0
end
