require 'multi_json'

# OkJson won't work because it doesn't serialize symbols
# in the same way yajl and json do.
if MultiJson.respond_to?(:adapter)
  raise "Please install the yajl-ruby or json gem" if MultiJson.adapter.to_s == 'MultiJson::Adapters::OkJson'
elsif MultiJson.respond_to?(:engine)
  raise "Please install the yajl-ruby or json gem" if MultiJson.engine.to_s == 'MultiJson::Engines::OkJson'
end

module ResquePauseHelper
  class << self
    DEFAULT_GLOBAL_PAUSE_KEY = "pause:all"

    def paused?(queue)
      !Resque.redis.mget("pause:queue:#{queue}", global_pause_key).all?(&:nil?)
    end

    def pause(queue)
      Resque.redis.set "pause:queue:#{queue}", true
    end

    def unpause(queue)
      Resque.redis.del "pause:queue:#{queue}"
    end

    def global_pause()
      Resque.redis.set global_pause_key, true
    end

    def global_unpause()
      Resque.redis.del global_pause_key
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

    def global_pause_key=(key)
      @global_pause_key = key
    end

    def global_pause_key
      @global_pause_key ||= DEFAULT_GLOBAL_PAUSE_KEY
    end
  end
end
