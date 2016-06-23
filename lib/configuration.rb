module ResquePauseHelper
  class Configuration
    DEFAULT_GLOBAL_PAUSE_TOKEN = "pause:all"

    attr_accessor :global_pause_token

    def initialize
      @global_pause_token = DEFAULT_GLOBAL_PAUSE_TOKEN
    end
  end
end
