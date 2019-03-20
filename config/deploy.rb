require 'mina/rails'
require 'mina/git'
require 'mina/puma'
require 'mina/npm'
require 'mina/rbenv'
require 'mina/bundler'

set :domain, '128.199.69.107'
set :application_name, 'myapp'
set :deploy_to, '/var/www/myapp'
set :repository, 'https://github.com/weyewe/mina-ansible.git'
set :branch, 'master'
set :user, 'app'
# set :identity_file, '/Users/ekyfauzi/.ssh/nord.pem' 

# task :production do
#   set :rails_env, 'production'
#   set :domain, '3.1.90.63'
#   set :commit, 'v2.6.0'
# end

# task :staging do
#   set :branch, 'release/v1.0.0'
#   set :rails_env, 'production'
# end




# section config to adjust ansible result to this mina rbenv 
# https://github.com/mina-deploy/mina-docs/blob/master/source/settings/current_path.md
# can we change the current path from  default to **current**
# we want to point it to **application** 


# then, where the fuck will it create release folder? and the symlink logic?
# set :current_path, "application"




# section RBENV 
set :rbenv_path, "/home/app/.rbenv"
# from this dude https://albertogrespan.com/blog/deploying-jekyll-with-mina-and-rbenv/
task :remote_environment do
  # If you're using rbenv, use this to load the rbenv environment.
  # Be sure to commit your .ruby-version or .rbenv-version to your repository.
  invoke :'rbenv:load'

  # For those using RVM, use this to load an RVM version@gemset.
  # invoke :'rvm:use', 'ruby-1.9.3-p125@default'
end

# section PUMA? << will come later after deploy 
# https://github.com/untitledkingdom/mina-puma

# already created and symlinked by ansible. 
# will it be problematic if we double symlink
set :shared_dirs, fetch(:shared_dirs, []).push('log')


# already created and symlinked by ansible 
set :shared_dirs, fetch(:shared_dirs, []).push('tmp')
set :shared_files, fetch(:shared_files, []).push(
  'config/database.yml',
  'config/puma.rb',
  'config/scout_apm.yml',
  'config/application.yml',
  '.env',
  '.env.production',
  'config/secrets.yml',
  'config/initializers/app_secrets.rb',
)


 
set :puma_pid, "#{fetch(:deploy_to)}/shared/pids/puma.pid"
set :puma_socket, "#{fetch(:deploy_to)}/shared/pids/puma.sock"
set :puma_state, "#{fetch(:deploy_to)}/shared/pids/puma.state"

set :pumactl_socket, "#{fetch(:deploy_to)}/shared/pids/pumactl.sock"


# set :unicorn_pid, 
# set :rvm_path, '$HOME/.rvm/bin/rvm'
# set :rvm_use_path, '$HOME/.rvm/bin/rvm'


 
 
task :setup do
  command %(mkdir -p "#{fetch(:deploy_to)}/shared/sockets")
  command %(chmod g+rx,u+rwx "#{fetch(:deploy_to)}/shared/sockets")

  command %(mkdir -p "#{fetch(:deploy_to)}/shared/log")
  command %(chmod g+rx,u+rwx "#{fetch(:deploy_to)}/shared/log")

  command %(mkdir -p "#{fetch(:deploy_to)}/shared/config")
  command %(chmod g+rx,u+rwx "#{fetch(:deploy_to)}/shared/config")

  command %(mkdir -p "#{fetch(:deploy_to)}/shared/config/initializers")
  command %(chmod g+rx,u+rwx "#{fetch(:deploy_to)}/shared/config/initializers")

  command %(touch "#{fetch(:deploy_to)}/shared/config/database.yml")
  command %(echo "-----> Be sure to edit 'shared/config/database.yml'.")

  command %(touch "#{fetch(:deploy_to)}/shared/config/secrets.yml")
  command %(echo "-----> Be sure to edit 'shared/config/secrets.yml'.")
  command %(touch "#{fetch(:deploy_to)}/shared/config/application.yml")
  command %(echo '-----> Be sure to edit for FIGARO 'shared/config/application.yml'.')

  command %(touch "#{fetch(:deploy_to)}/shared/config/initializers/app_secrets.rb")
  command %(echo '-----> Be sure to edit 'shared/config/initializers/app_secrets.rb'.')

  # sidekiq needs a place to store its pid file and log file
  command %(mkdir -p "#{fetch(:deploy_to)}/shared/pids/")
  command %(chmod g+rx,u+rwx "#{fetch(:deploy_to)}/shared/pids")
end

desc 'Deploys the current version to the server.'
task :deploy do
  deploy do
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'rails:db_migrate'
    command %(RAILS_ENV=production NODE_ENV=production yarn)
    invoke :'rails:assets_precompile'
    invoke :'deploy:cleanup'

    on :launch do
      in_path(fetch(:current_path)) do
        
        command %(echo "the puma: #{fetch(:bundle_prefix)} puma in current_path: #{fetch(:current_path)} ")
        command %(echo " pumactl_sock: #{fetch(:pumactl_socket)}, sock: #{fetch(:puma_socket)} ")
        
        # invoke :'unicorn:restart'
        invoke :'puma:phased_restart'
      end
    end
  end
end

desc 'Checks out the current release tag'
task :checkout_release do
  command %(git clone --branch "#{fetch(:version)}" "#{fetch(:repository)}" .)
end




# related with puma 
# deploy.rb
# set :puma_state, "#{fetch(:shared_path)}/tmp/sockets/puma.state"
# set :puma_socket, "#{fetch(:shared_path)}/tmp/sockets/puma.sock"
# # set :puma_pid, "#{fetch(:shared_path)}/tmp/pids/puma.pid"
# set :start_port, 10000

# task puma_start: :remote_environment do
#   command %[
#     if [ -e '#{fetch(:puma_pid)}' ]; then
#       echo 'Puma is already running'
#     else
#       echo 'Start Puma'
#       cd #{fetch(:current_path)} && bundle exec puma -q -d -e #{fetch(:rails_env)} -C #{fetch(:current_path)}/config/puma.rb -p #{fetch(:start_port)} -S #{fetch(:puma_state)} -b ""tcp://128.199.72.136:10000"" --pidfile #{fetch(:puma_pid)}
#     fi
#   ]
# end

# task puma_restart: :remote_environment do
#   command %[
#     if [ -e '#{fetch(:puma_pid)}' ]; then
#       echo 'Restart Puma'
#       cd #{fetch(:current_path)} && bundle exec pumactl -S #{fetch(:puma_state)} restart
#     else
#       echo 'Start Puma'
#       cd #{fetch(:current_path)} && bundle exec puma -q -d -e #{fetch(:rails_env)} -C #{fetch(:current_path)}/config/puma.rb -p #{fetch(:start_port)} -S #{fetch(:puma_state)} -b "unix://#{fetch(:puma_socket)}" --pidfile #{fetch(:puma_pid)}
#     fi
#   ]
# end

# task puma_stop: :remote_environment do
#   command %[
#     if [ -e '#{fetch(:puma_pid)}' ]; then
#       cd #{fetch(:current_path)} && bundle exec pumactl -S #{fetch(:puma_state)} stop
#       rm #{fetch(:puma_socket)}
#       rm #{fetch(:puma_state)}
#       rm #{fetch(:puma_pid)}
#     else
#       echo 'Puma is not running. Phew!!!'
#     fi
#   ]
# end



# require 'mina/rails'
# require 'mina/git'
# require 'mina/rbenv'  # for rbenv support. (https://rbenv.org)
# # require 'mina/rvm'    # for rvm support. (https://rvm.io)

# # Basic settings:
# #   domain       - The hostname to SSH to.
# #   deploy_to    - Path to deploy into.
# #   repository   - Git repo to clone from. (needed by mina/git)
# #   branch       - Branch name to deploy. (needed by mina/git)

# set :application_name, 'foobar'
# set :domain, 'foobar.com'
# set :deploy_to, '/var/www/foobar.com'
# set :repository, 'git://...'
# set :branch, 'master'

# # Optional settings:
# #   set :user, 'foobar'          # Username in the server to SSH to.
# #   set :port, '30000'           # SSH port number.
# #   set :forward_agent, true     # SSH forward_agent.

# # Shared dirs and files will be symlinked into the app-folder by the 'deploy:link_shared_paths' step.
# # Some plugins already add folders to shared_dirs like `mina/rails` add `public/assets`, `vendor/bundle` and many more
# # run `mina -d` to see all folders and files already included in `shared_dirs` and `shared_files`
# # set :shared_dirs, fetch(:shared_dirs, []).push('public/assets')
# # set :shared_files, fetch(:shared_files, []).push('config/database.yml', 'config/secrets.yml')

# # This task is the environment that is loaded for all remote run commands, such as
# # `mina deploy` or `mina rake`.
# task :remote_environment do
#   # If you're using rbenv, use this to load the rbenv environment.
#   # Be sure to commit your .ruby-version or .rbenv-version to your repository.
#   # invoke :'rbenv:load'

#   # For those using RVM, use this to load an RVM version@gemset.
#   # invoke :'rvm:use', 'ruby-1.9.3-p125@default'
# end

# # Put any custom commands you need to run at setup
# # All paths in `shared_dirs` and `shared_paths` will be created on their own.
# task :setup do
#   # setup: provisioning, cold deploy has been done by the ansible
#   # we need puma for continuous deployment  
#   # command %{rbenv install 2.3.0 --skip-existing}
# end

# desc "Deploys the current version to the server."
# task :deploy do
#   # uncomment this line to make sure you pushed your local branch to the remote origin
#   # invoke :'git:ensure_pushed'
#   deploy do
#     # Put things that will set up an empty directory into a fully set-up
#     # instance of your project.
#     invoke :'git:clone'
#     invoke :'deploy:link_shared_paths'
#     invoke :'bundle:install'
#     invoke :'rails:db_migrate'
#     invoke :'rails:assets_precompile'
#     invoke :'deploy:cleanup'

#     on :launch do
#       in_path(fetch(:current_path)) do
#         command %{mkdir -p tmp/}
#         command %{touch tmp/restart.txt}
#       end
#     end
#   end

#   # you can use `run :local` to run tasks on local machine before of after the deploy scripts
#   # run(:local){ say 'done' }
# end

# # For help in making your deploy script, see the Mina documentation:
# #
# #  - https://github.com/mina-deploy/mina/tree/master/docs
