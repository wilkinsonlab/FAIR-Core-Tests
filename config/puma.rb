# Bounded concurrency so a burst of legitimate traffic queues and sheds load
# instead of consuming unbounded host CPU/RAM (see CHANGELOG 0.5.0).
workers Integer(ENV.fetch('WEB_CONCURRENCY', 2))
threads_count = Integer(ENV.fetch('PUMA_MAX_THREADS', 3))
threads threads_count, threads_count

# OS-level TCP backlog (set via the bind URL, not a standalone DSL method):
# once this many connections are already waiting, additional clients get
# connection-refused/reset immediately rather than queueing forever behind
# an overloaded worker pool.
bind "tcp://0.0.0.0:#{ENV.fetch('PORT', 8282)}?backlog=#{Integer(ENV.fetch('PUMA_BACKLOG', 32))}"

# Kill and restart a worker that hangs on a single request (e.g. a slow
# upstream resource) instead of letting it block that worker's threads
# indefinitely.
worker_timeout Integer(ENV.fetch('PUMA_WORKER_TIMEOUT', 300))
