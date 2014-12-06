require 'resque'
require 'resque/server'
require File.expand_path(File.join('../','resque_pause_helper'), File.dirname(__FILE__))

# Extends Resque Web Based UI.
# Structure has been borrowed from ResqueScheduler.
module ResquePause
  module Server

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

          def global_paused?
            ResquePauseHelper.global_paused?
          end
        end

        mime_type :json, 'application/json'

        get '/pause' do
          case request.accept.first
          when /json/
            content_type :json
            resque.queues.inject({"GLOBAL_PAUSE" => ResquePauseHelper.global_paused?}) do |pause_status, queue|
              pause_status[queue] = ResquePauseHelper.paused?(queue)
              pause_status
            end.to_json
          else
            erb File.read(ResquePause::Server.erb_path('pause.erb'))
          end
        end

        post '/pause' do
          params.merge!(MultiJson.load(request.body.read.to_s)) if /json/ =~ request.content_type

          pause = params['pause'].to_s == "true"

          unless params['queue_name'].empty?
            case params['queue_name']
            when "GLOBAL_PAUSE"
              if pause
                ResquePauseHelper.global_pause
              else
                ResquePauseHelper.global_unpause
              end
            else
              if pause
                ResquePauseHelper.pause(params['queue_name'])
              else
                ResquePauseHelper.unpause(params['queue_name'])
              end
            end
          end
          content_type :json
          ResquePauseHelper.encode(:queue_name => params['queue_name'], :paused => pause)
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
