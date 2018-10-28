set :stages, %w(production development staging)
set :default_stage, "staging"
set :application, "danbooru"
set :repo_url,  "git://github.com/maelask3/danbooru.git"
set :scm, :git
<<<<<<< HEAD
set :deploy_to, "/var/www/danbooru2"
=======
set :deploy_to, "/var/www/danbooru"
>>>>>>> 271c50d1c88315d35d2b3161d0c7559001398455
set :rbenv_ruby, "2.5.1"
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle')
set :branch, ENV.fetch("branch", "master")
