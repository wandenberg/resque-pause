require 'rack/test'

if !system("which redis-server")
  puts '', "** can't find `redis-server` in your path"
  abort ''
end

begin
  require 'simplecov'
  SimpleCov.start do
    add_filter '/spec/'
  end
  SimpleCov.coverage_dir 'coverage'
rescue LoadError
  # ignore simplecov in ruby < 1.9
end

begin
  require 'bundler'
  Bundler.setup
  Bundler.require(:default, :development)
rescue LoadError
  puts 'Bundler is not installed, you need to gem install it in order to run the specs.'
  exit 1
end

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir[File.expand_path('support/**/*.rb', File.dirname(__FILE__))].each { |f| require f }

# Requires lib.
Dir[File.expand_path('../lib/**/*.rb', File.dirname(__FILE__))].each { |f| require f }

ENV['REDIS_URL'] = 'redis://127.0.0.1:9736'

RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  config.order = "random"

  config.before(:suite) do
    puts '', 'Starting redis for testing at localhost:9736...', ''
    FileUtils.rm_f('spec/redis-test.pid')
    `redis-server #{File.dirname(File.expand_path(__FILE__))}/redis-test.conf`
    pid = ''
    while pid.empty? do
      pid = File.read('spec/redis-test.pid').chomp rescue ''
    end
    Resque.redis = ENV['REDIS_URL']
  end

  config.before(:each) do
    Redis.current.flushall
    allow(Kernel).to receive(:sleep)
  end

  config.after(:suite) do
    pid = File.read('spec/redis-test.pid').chomp rescue ''
    puts '', '', 'Killing test redis server...'
    Process.kill('KILL', pid.to_i)
    FileUtils.rm_f('spec/redis-test.pid')
    FileUtils.rm_f('spec/dumb.rdb')
  end
end
