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

  it "should execute the job when queue is unpaused after being paused" do
    Resque.enqueue(PauseJob)
    expect(Resque.size('test')).to eq(1)

    job = Resque.reserve('test')
    ResquePauseHelper.pause('test')
    job.perform
    expect(Resque.size('test')).to eq(1)

    ResquePauseHelper.unpause('test')

    expect(PauseJob).to receive(:perform)
    Resque.reserve('test').perform
    expect(Resque.size('test')).to eq(0)
  end

  it "should not reserve the job when global pause is on" do
    Resque.enqueue(PauseJob)
    ResquePauseHelper.global_pause_on()
    expect(PauseJob).not_to receive(:perform)

    expect(Resque.reserve('test')).to be_nil
  end

  it "should not execute the job when the global pause is on" do
    Resque.enqueue(PauseJob)
    expect(Resque.size('test')).to eq(1)

    job = Resque.reserve('test')
    ResquePauseHelper.global_pause_on()
    job.perform

    expect(Resque.size('test')).to eq(1)
  end

  it "should execute the job when the global pause was switched on and then off" do
    Resque.enqueue(PauseJob)
    expect(Resque.size('test')).to eq(1)

    job = Resque.reserve('test')
    ResquePauseHelper.global_pause_on()
    job.perform
    expect(Resque.size('test')).to eq(1)

    ResquePauseHelper.global_pause_off()

    expect(PauseJob).to receive(:perform)
    Resque.reserve('test').perform
    expect(Resque.size('test')).to eq(0)
  end

  it "should not execute the job when the queue is paused, and then the global pause is switched on and then back off" do
    Resque.enqueue(PauseJob)
    expect(Resque.size('test')).to eq(1)

    job = Resque.reserve('test')
    ResquePauseHelper.pause('test')

    ResquePauseHelper.global_pause_on()
    ResquePauseHelper.global_pause_off()

    job.perform

    expect(Resque.size('test')).to eq(1)
  end

  it "should not reserve the job when the queue is paused, and then the global pause is switched on and then back off" do
    Resque.enqueue(PauseJob)
    ResquePauseHelper.pause('test')
    ResquePauseHelper.global_pause_on()
    ResquePauseHelper.global_pause_off()

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

  it "should allow the global pause token to be configurable" do
    pause_token = "my_new_pause_token"

    ResquePauseHelper.configure do |config|
      config.global_pause_token = pause_token
    end

    Resque.enqueue(PauseJob)
    ResquePauseHelper.global_pause_on()

    expect(Resque.redis.get(pause_token)).not_to be_nil
  end

  it "should still handle global pauses with a client-configured token" do
    pause_token = "my_new_pause_token"

    ResquePauseHelper.configure do |config|
      config.global_pause_token = pause_token
    end

    Resque.enqueue(PauseJob)
    expect(Resque.size('test')).to eq(1)

    job = Resque.reserve('test')
    ResquePauseHelper.global_pause_on()
    job.perform

    expect(Resque.size('test')).to eq(1)
  end

  it "should still handle switching global pauses back off with a client-configured token" do
    pause_token = "my_new_pause_token"

    ResquePauseHelper.configure do |config|
      config.global_pause_token = pause_token
    end

    Resque.enqueue(PauseJob)
    expect(Resque.size('test')).to eq(1)

    job = Resque.reserve('test')
    ResquePauseHelper.global_pause_on()
    job.perform
    expect(Resque.size('test')).to eq(1)

    ResquePauseHelper.global_pause_off()

    expect(PauseJob).to receive(:perform)
    Resque.reserve('test').perform
    expect(Resque.size('test')).to eq(0)
  end

  it "should indicate whether the global pause is on" do
    expect(ResquePauseHelper.global_pause_on?).to be false
    ResquePauseHelper.global_pause_on()
    expect(ResquePauseHelper.global_pause_on?).to be true
    ResquePauseHelper.global_pause_off()
    expect(ResquePauseHelper.global_pause_on?).to be false
  end
end
