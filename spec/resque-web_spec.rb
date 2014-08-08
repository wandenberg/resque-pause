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
    expect(last_response).to be_ok
  end

  it "should list all registered queues" do
    get '/pause'
    expect(last_response.body).to include("queue1")
    expect(last_response.body).to include("queue2")
    expect(last_response.body).to include("queue3")
  end

  it "should check paused queues" do
    ResquePauseHelper.pause("queue2")

    get '/pause'
    expect(last_response.body).to include(%q{<input class="pause" type="checkbox" value="queue1" ></input>})
    expect(last_response.body).to include(%q{<input class="pause" type="checkbox" value="queue2" checked></input>})
    expect(last_response.body).to include(%q{<input class="pause" type="checkbox" value="queue3" ></input>})
  end


  it "should pause a queue" do
    post "/pause", :queue_name => "queue3", :pause => true

    expect(ResquePauseHelper.paused?("queue3")).to be_truthy
  end

  it "should return a json when pause a queue" do
    post "/pause", :queue_name => "queue3", :pause => true

    expect(last_response.headers["Content-Type"]).to eq("application/json")
    expect(last_response.body).to eq({ :queue_name => "queue3", :paused => true }.to_json)
  end

  it "should unpause a queue" do
    ResquePauseHelper.pause("queue2")
    post "/pause", :queue_name => "queue2", :pause => false

    expect(ResquePauseHelper.paused?("queue2")).to be_falsey
  end

  it "should return a json when unpause a queue" do
    post "/pause", :queue_name => "queue2", :pause => false

    expect(last_response.headers["Content-Type"]).to eq("application/json")
    expect(last_response.body).to eq({ :queue_name => "queue2", :paused => false }.to_json)
  end

  it "should return static files" do
    get "/pause/public/pause.js"
    expect(last_response.body).to eq(File.read(File.expand_path('../lib/resque-pause/server/public/pause.js', File.dirname(__FILE__))))
  end

end
