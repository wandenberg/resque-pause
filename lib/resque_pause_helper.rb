module ResquePauseHelper
  class << self
    def paused?(queue)
      !Resque.redis.get("pause:queue:#{queue}").nil?
    end

    def pause(queue)
      Resque.redis.set "pause:queue:#{queue}", true
    end

    def unpause(queue)
      Resque.redis.del "pause:queue:#{queue}"
    end

    def enqueue_job(args)
      Resque.redis.lpush("queue:#{args[:queue]}", Resque.encode(:class => args[:class], :args => args[:args]))
    end

    def dequeue_job(args)
      Resque.redis.lpop("queue:#{args[:queue]}")
    end

    def check_paused(args)
      if ResquePauseHelper.paused?(args[:queue])
        enqueue_job(args)
        raise Resque::Job::DontPerform.new "Queue #{args[:queue]} is paused!"
      end
    end
  end
end
