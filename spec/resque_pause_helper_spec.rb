require 'spec_helper'

class PauseJob
  @queue = :test

  def self.perform(*args)
  end
end

describe ResquePauseHelper do

  context "when check queue status" do
    it "should return return false if don't have register on redis" do
      Resque.redis.del "pause:queue:queue1"

      expect(subject.paused?("queue1")).to be_falsey
    end

    it "should return return true if have register on redis" do
      Resque.redis.set "pause:queue:queue1", "AnyValue"

      expect(subject.paused?("queue1")).to be_truthy
    end
  end

  context "when pause a queue" do
    it "should register a unregistred queue" do
      Resque.redis.del "pause:queue:queue1"
      subject.pause("queue1")

      expect(subject.paused?("queue1")).to be_truthy
    end

    it "should register again a registred queue" do
      Resque.redis.set "pause:queue:queue1", "AnyValue"
      expect { subject.pause("queue1") }.to_not raise_error

      expect(Resque.redis.get("pause:queue:queue1")).not_to be_nil
      expect(Resque.redis.get("pause:queue:queue1")).to be_truthy
    end
  end

  context "when unpause a queue" do
    it "should unregister a unregistred queue" do
      Resque.redis.del "pause:queue:queue1"
      subject.unpause("queue1")

      expect(subject.paused?("queue1")).to be_falsey
    end

    it "should unregister a registred queue" do
      Resque.redis.set "pause:queue:queue1", "AnyValue"
      expect { subject.unpause("queue1") }.to_not raise_error

      expect(Resque.redis.get("pause:queue:queue1")).to be_nil
    end
  end

  context "when enqueue a job" do
    it "should enqueue on a empty queue" do
      Resque.redis.del "queue:queue1"

      subject.enqueue_job(:queue => "queue1", :class => PauseJob, :args => nil)

      expect(Resque.redis.llen("queue:queue1").to_i).to eq(1)
    end

    it "should enqueue on beginning of a queue" do
      Resque.redis.lpush "queue:queue1", {:class => PauseJob, :args => [1, 2]}.to_json

      subject.enqueue_job(:queue => "queue1", :class => PauseJob, :args => [1])

      jobs = Resque.redis.lrange('queue:queue1', 0, 10)

      expect(jobs.count).to eq(2)
      expect(jobs[0]).to eq({:class => PauseJob, :args => [1]}.to_json)
      expect(jobs[1]).to eq({:class => PauseJob, :args => [1, 2]}.to_json)
    end
  end

  context "when checking if queue is paused" do
    it "should check if queue is paused" do
      expect(subject).to receive(:paused?).with("queue1")

      subject.check_paused(:queue => "queue1")
    end

    it "should not raise error when queue is not paused" do
      expect(subject).to receive(:paused?).with("queue1").and_return(false)

      expect { subject.check_paused(:queue => "queue1") }.to_not raise_error
    end

    it "should raise error when queue is paused" do
      allow(subject).to receive(:enqueue_job)
      allow(subject).to receive(:paused?).with("queue1").and_return(true)

      expect { subject.check_paused(:queue => "queue1") }.to raise_error(Resque::Job::DontPerform)
    end

    it "should enqueue the job again when queue is paused" do
      allow(subject).to receive(:paused?).with("queue1").and_return(true)

      args = {:queue => "queue1", :class => PauseJob, :args => [1, 2]}
      expect(subject).to receive(:enqueue_job).with(args)

      subject.check_paused(args) rescue nil
    end
  end

end
