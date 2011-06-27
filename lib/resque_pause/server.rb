# Extends Resque Web Based UI.
# Structure has been borrowed from ResqueScheduler.
module ResquePause
  module Server
    include Resque::Helpers

    def self.erb_path(filename)
      File.join(File.dirname(__FILE__), 'server', 'views', filename)
    end

    def self.public_path(filename)
      File.join(File.dirname(__FILE__), 'server', 'public', filename)
    end

    def self.included(base)

      base.class_eval do

        helpers do
          def paused?(queue)
            ResquePauseHelper.paused?(queue)
          end
        end

        mime_type :json, 'application/json'

        get '/pause' do
          erb File.read(ResquePause::Server.erb_path('pause.erb'))
        end

        post '/pause' do
          ResquePauseHelper.pause(params['queue_name']) unless params['queue_name'].empty?
          content_type :json
          encode(:queue_name => params['queue_name'], :paused => true)
        end

        post '/unpause' do
          ResquePauseHelper.unpause(params['queue_name']) unless params['queue_name'].empty?
          content_type :json
          encode(:queue_name => params['queue_name'], :paused => false)
        end

        get /pause\/public\/([a-z]+\.[a-z]+)/ do
          send_file ResquePause::Server.public_path(params[:captures].first)
        end
      end
    end

    Resque::Server.tabs << 'Pause'
  end
end

Resque.extend ResquePause
Resque::Server.class_eval do
  include ResquePause::Server
end
