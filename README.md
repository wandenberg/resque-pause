# Resque Pause [![alt build status][1]][2]

[1]: https://secure.travis-ci.org/wandenberg/resque-pause.png
[2]: http://travis-ci.org/#!/wandenberg/resque-pause


A [Resque][rq] plugin. Requires Resque 1.9.10.

resque-pause adds functionality to pause resque jobs through the web interface.

Using a `pause` allows you to stop the job for a slice of time.
The job finish the process it are doing and don't get a new task to do,
until the queue is released.
You can use this functionality to do some maintenance whithout kill workers, for example.

Usage / Examples
----------------

### Single Job Instance

```ruby
require 'resque-pause'

class UpdateNetworkGraph
  extend Resque::Plugins::Pause
  @queue = :network_graph

  def self.perform(repo_id)
    heavy_lifting
  end
end
```

### Pausing Individual Queues

To pause the queue:

```ruby
ResquePauseHelper.pause(:network_graph)
```

Then, to unpause the queue:

```ruby
ResquePauseHelper.unpause(:network_graph)
```

Single-queue pause is achieved by storing a pause/queue key in Redis.


### Global Pause

You can also pause all the queues at once.

To switch on a global pause:

```ruby
ResquePauseHelper.global_pause()
```

Then, to remove a global pause:

```ruby
ResquePauseHelper.global_unpause()
```

This global pause doesn't interact with any pauses on individual queues. That means, switching the global pause on and off should preserve whatever pauses you might have in place before and even during the global pause period.

An anology would be with light switches and circuit breakers. Positioning light switches is like pausing individual queues. Whatever their position before you flip the breaker (impose a global pause). They'll maintain that position after the global pause.

### Default behaviour

* When the job instance try to execute and the queue is paused, the job is paused for a slice of time.
* If the queue still paused after this time the job will abort and will be enqueued again with the same arguments.


Resque-Web integration
----------------------

You have to load ResquePause to enable the Pause tab.

```ruby
require 'resque-pause/server'
```

Customise & Extend
==================

### Job pause check interval

The slice of time the job will wait for queue be unpaused before abort the job
could be changed with attribute @pause_check_interval.

By default the time is 10 seconds.

You can define the attribute in your job class in seconds.

```ruby
class UpdateNetworkGraph
  extend Resque::Plugins::Pause
  @queue = :network_graph
  @pause_check_interval = 30

  def self.perform(repo_id)
    heavy_lifting
  end
end
```

The above modification will ensure the job will wait for 30 seconds before abort.

### Global pause Redis key

To change the exact key that will be put into redis to signal a global pause, use the `global_pause_key` config

````ruby
ResquePauseHelper.global_pause_key = "my_custom_key"
````

Install
=======

```bash
$ gem install resque-pause
```

[rq]: http://github.com/defunkt/resque
[resque-pause]: https://github.com/wandenberg/resque-pause
