module Resque
  class Job
    class <<self
      alias_method :origin_before_pause_reserve, :reserve

      def reserve(queue)
        return nil if ResquePauseHelper.paused?(queue)
        origin_before_pause_reserve(queue)
      end

    end
  end
end
