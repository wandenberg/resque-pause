require 'multi_json'

# OkJson won't work because it doesn't serialize symbols
# in the same way yajl and json do.
if MultiJson.respond_to?(:adapter)
  raise "Please install the yajl-ruby or json gem" if MultiJson.adapter.to_s == 'MultiJson::Adapters::OkJson'
elsif MultiJson.respond_to?(:engine)
  raise "Please install the yajl-ruby or json gem" if MultiJson.engine.to_s == 'MultiJson::Engines::OkJson'
end

module ResquePause
  # Methods used by various classes in Resque.
  module Helpers
    class DecodeException < StandardError; end

    # Given a Ruby object, returns a string suitable for storage in a queue.
    def encode(object)
      if MultiJson.respond_to?(:dump) && MultiJson.respond_to?(:load)
        MultiJson.dump object
      else
        MultiJson.encode object
      end
    end

    # Given a string, returns a Ruby object.
    def decode(object)
      return unless object

      begin
        if MultiJson.respond_to?(:dump) && MultiJson.respond_to?(:load)
          MultiJson.load object
        else
          MultiJson.decode object
        end
      rescue ::MultiJson::DecodeError => e
        raise DecodeException, e.message, e.backtrace
      end
    end
  end
end
