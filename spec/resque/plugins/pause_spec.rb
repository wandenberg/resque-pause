require 'spec_helper'

class PauseJob
  extend Resque::Plugins::Pause
  @queue = :test

  def self.perform(*args)
  end
end

describe Resque::Plugins::Pause do
  it "should be compliance with Resqu::Plugin document" do
    expect { Resque::Plugin.lint(Resque::Plugins::Pause) }.to_not raise_error
  end

  it "should use at least resque version 1.8.0" do
    major, minor, patch = Resque::Version.split('.')
    major.to_i.should == 1
    minor.to_i.should >= 8
  end

  it "should execute the job when queue is not paused" do
    Resque.enqueue(PauseJob)
    PauseJob.should_receive(:perform)

    Resque.reserve('test').perform
  end

  it "should not execute the job when queue is paused" do
    ResquePauseHelper.pause('test')
    Resque.enqueue(PauseJob)
    PauseJob.should_not_receive(:perform)

    Resque.reserve('test').perform
  end

  it "should not change queued jobs when queue is paused" do
    ResquePauseHelper.pause('test')
    Resque.enqueue(PauseJob, 1)
    Resque.enqueue(PauseJob, 2)
    Resque.enqueue(PauseJob, 3)
    jobs = Resque.redis.lrange('queue:test', 0, 2)

    Resque.reserve('test').perform

    remaining_jobs = Resque.redis.lrange('queue:test', 0, 2)
    jobs.should == remaining_jobs
  end

  it "should back to execute the job when queue is unpaused" do
    Resque.enqueue(PauseJob)

    ResquePauseHelper.pause('test')
    Resque.reserve('test').perform
    Resque.size('test').should == 1

    ResquePauseHelper.unpause('test')
    Resque.reserve('test').perform
    Resque.size('test').should == 0
  end

end
