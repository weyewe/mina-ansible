### suggested 

# environment "production"

# bind  "unix:///{path_to_your_app}/shared/tmp/sockets/puma.sock"
# pidfile "/{path_to_your_app}/shared/tmp/pids/puma.pid"
# state_path "/{path_to_your_app}/shared/tmp/sockets/puma.state"
# directory "/{path_to_your_app}/current"

# workers 2
# threads 1,2

# daemonize true

# activate_control_app 'unix:///{path_to_your_app}/shared/tmp/sockets/pumactl.sock'

# prune_bundler





################ this is the generated shite 

# workers 1

# threads 0, 16 

# environment "production" 
# path_to_app = "/var/www/myapp"
# shared_dir = "#{path_to_app}/shared" 
# stdout_redirect "#{shared_dir}/log/puma.stdout.log", "#{shared_dir}/log/puma.stderr.log", true 






# bind "tcp://128.199.72.136:10000"
# pidfile "#{shared_dir}/pids/puma.pid"
# state_path "#{shared_dir}/pids/puma.state"
# directory "#{path_to_app}/current"
# preload_app! 


# before_fork do
#   ActiveRecord::Base.connection_pool.disconnect! if defined?(ActiveRecord)
# end

# on_worker_boot do
#   ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
# end



##########################################  this is for local 



# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#
threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
threads threads_count, threads_count

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
#
port        ENV.fetch("PORT") { 3000 }

# Specifies the `environment` that Puma will run in.
#
environment ENV.fetch("RAILS_ENV") { "development" }

# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked webserver processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
#
# workers ENV.fetch("WEB_CONCURRENCY") { 2 }

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory.
#
# preload_app!

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart
