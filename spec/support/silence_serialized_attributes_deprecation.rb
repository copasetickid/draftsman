# SerializedAttributes is deprecated in Rails 4.2.x, and will be removed in
#   Rails 5. Draftsman spews a ton of deprecation warnings about this issue.
#
#   More info: https://github.com/airblade/paper_trail/issues/416
#
# TODO: when migrating to Rails 5, remove this initializer

if Draftsman::VERSION.to_f < 1.0
  current_behavior = ActiveSupport::Deprecation.behavior
  ActiveSupport::Deprecation.behavior = lambda do |message, callstack|
    return if message =~ /`serialized_attributes` is deprecated without replacement/ && callstack.any? { |m| m =~ /draftsman/ }
    Array.wrap(current_behavior).each { |behavior| behavior.call(message, callstack) }
  end
else
  warn 'FIXME: Draftsman initializer to suppress deprecation warnings can be safely removed.'
end
