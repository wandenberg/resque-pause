module Resque
  module Plugins
    module Pause
      PAUSE_CHECK_INTERVAL = 10 #seconds to wait when queue is paused

      def before_perform_pause(*args)
        if ResquePauseHelper.paused?(@queue)
          Kernel.sleep(@pause_check_interval || Resque::Plugins::Pause::PAUSE_CHECK_INTERVAL)
          ResquePauseHelper.check_paused(:queue => @queue, :class => self, :args => args)
        end
      end
    end
  end
end
