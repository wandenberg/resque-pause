require 'multi_json'
require 'configuration'

# OkJson won't work because it doesn't serialize symbols
# in the same way yajl and json do.
if MultiJson.respond_to?(:adapter)
  raise "Please install the yajl-ruby or json gem" if MultiJson.adapter.to_s == 'MultiJson::Adapters::OkJson'
elsif MultiJson.respond_to?(:engine)
  raise "Please install the yajl-ruby or json gem" if MultiJson.engine.to_s == 'MultiJson::Engines::OkJson'
end

module ResquePauseHelper
  class << self

    def configure(&block)
      yield(configuration)
      configuration
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def reset_configuration!
      @configuration = nil
    end

    def paused?(queue)
      ![
          Resque.redis.get("pause:queue:#{queue}"),
          Resque.redis.get(ResquePauseHelper.configuration.global_pause_token)
      ].all?(&:nil?)
    end

    def pause(queue)
      Resque.redis.set "pause:queue:#{queue}", true
    end

    def unpause(queue)
      Resque.redis.del "pause:queue:#{queue}"
    end

    def global_pause_on()
      Resque.redis.set ResquePauseHelper.configuration.global_pause_token, true
    end

    def global_pause_off()
      Resque.redis.del ResquePauseHelper.configuration.global_pause_token
    end

    def global_pause_on?()
      !!Resque.redis.get(ResquePauseHelper.configuration.global_pause_token)
    end

    def enqueue_job(args)
      Resque.redis.lpush("queue:#{args[:queue]}", ResquePauseHelper.encode(:class => args[:class].to_s, :args => args[:args]))
    end

    def check_paused(args)
      if ResquePauseHelper.paused?(args[:queue])
        enqueue_job(args)
        raise Resque::Job::DontPerform.new "Queue #{args[:queue]} is paused!"
      end
    end

    # Given a Ruby object, returns a string suitable for storage in a queue.
    def encode(object)
      if MultiJson.respond_to?(:dump) && MultiJson.respond_to?(:load)
        MultiJson.dump object
      else
        MultiJson.encode object
      end
    end
  end
end
