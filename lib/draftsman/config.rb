require 'singleton'

module Draftsman
  class Config
    include Singleton
    attr_accessor :serializer, :timestamp_field

    def initialize
      @timestamp_field = :created_at
      @mutex = Mutex.new
      @serializer      = Draftsman::Serializers::Yaml
    end

    # Indicates whether Draftsman is on or off. Default: true.
    def enabled
      @mutex.synchronize { !!@enabled }
    end

    def enabled=(enable)
      @mutex.synchronize { @enabled = enable }
    end
  end
end
