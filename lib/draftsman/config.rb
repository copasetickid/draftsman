require 'singleton'

module Draftsman
  class Config
    include Singleton
    attr_accessor :serializer, :timestamp_field

    def initialize
      @timestamp_field = :created_at
      @serializer      = Draftsman::Serializers::Yaml
    end
  end
end
