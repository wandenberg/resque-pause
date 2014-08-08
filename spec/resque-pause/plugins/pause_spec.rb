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

  it "should use at least resque version 1.9.10" do
    major, minor, patch = Resque::Version.split('.')
    expect(major.to_i).to eq(1)
    expect(minor.to_i).to be >= 9
    expect(patch.to_i).to be >= 10 if minor.to_i  == 9
  end

  it "should execute the job when queue is not paused" do
    Resque.enqueue(PauseJob)
    expect(PauseJob).to receive(:perform)

    Resque.reserve('test').perform
  end

  it "should not execute the job when queue is paused" do
    Resque.enqueue(PauseJob)
    expect(Resque.size('test')).to eq(1)

    job = Resque.reserve('test')
    ResquePauseHelper.pause('test')
    job.perform

    expect(Resque.size('test')).to eq(1)
  end

  it "should not reserve the job when queue is paused" do
    ResquePauseHelper.pause('test')
    Resque.enqueue(PauseJob)
    expect(PauseJob).not_to receive(:perform)

    expect(Resque.reserve('test')).to be_nil
  end

  it "should not change queued jobs when queue is paused" do
    Resque.enqueue(PauseJob, 1)
    Resque.enqueue(PauseJob, 2)
    Resque.enqueue(PauseJob, 3)
    jobs = Resque.redis.lrange('queue:test', 0, 2)

    job = Resque.reserve('test')
    ResquePauseHelper.pause('test')
    job.perform

    remaining_jobs = Resque.redis.lrange('queue:test', 0, 2)
    expect(jobs).to eq(remaining_jobs)
  end

  it "should back to execute the job when queue is unpaused" do
    Resque.enqueue(PauseJob)

    job = Resque.reserve('test')
    ResquePauseHelper.pause('test')
    job.perform
    expect(Resque.size('test')).to eq(1)

    ResquePauseHelper.unpause('test')
    Resque.reserve('test').perform
    expect(Resque.size('test')).to eq(0)
  end

end
