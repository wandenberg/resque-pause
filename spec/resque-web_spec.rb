require 'spec_helper'

describe ResquePause::Server do
  include Rack::Test::Methods
  def app
    @app ||= Resque::Server.new
  end

  let :queues do
    Resque.redis.sadd(:queues, "queue1")
    Resque.redis.sadd(:queues, "queue2")
    Resque.redis.sadd(:queues, "queue3")
  end

  before do
    queues
  end

  it "should respond to /pause" do
    get '/pause'
    last_response.should be_ok
  end

  it "should list all registered queues" do
    get '/pause'
    last_response.body.should include("queue1")
    last_response.body.should include("queue2")
    last_response.body.should include("queue3")
  end

  it "should check paused queues" do
    ResquePauseHelper.pause("queue2")

    get '/pause'
    last_response.body.should include(%q{<input class="pause" type="checkbox" value="queue1" ></input>})
    last_response.body.should include(%q{<input class="pause" type="checkbox" value="queue2" checked></input>})
    last_response.body.should include(%q{<input class="pause" type="checkbox" value="queue3" ></input>})
  end


  it "should pause a queue" do
    post "/pause", :queue_name => "queue3", :pause => true

    ResquePauseHelper.paused?("queue3").should be_true
  end

  it "should return a json when pause a queue" do
    post "/pause", :queue_name => "queue3", :pause => true

    last_response.headers["Content-Type"].should == "application/json"
    last_response.body.should == { :queue_name => "queue3", :paused => true }.to_json
  end

  it "should unpause a queue" do
    ResquePauseHelper.pause("queue2")
    post "/pause", :queue_name => "queue2", :pause => false

    ResquePauseHelper.paused?("queue2").should be_false
  end

  it "should return a json when unpause a queue" do
    post "/pause", :queue_name => "queue2", :pause => false

    last_response.headers["Content-Type"].should == "application/json"
    last_response.body.should == { :queue_name => "queue2", :paused => false }.to_json
  end

  it "should return static files" do
    get "/pause/public/pause.js"
    last_response.body.should == File.read(File.expand_path('../lib/resque_pause/server/public/pause.js', File.dirname(__FILE__)))
  end

end
