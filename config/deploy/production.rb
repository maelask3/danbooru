set :user, "danbooru"
set :rails_env, "production"
server "192.168.122.191", :roles => %w(web app db), :primary => true

set :delayed_job_workers, 12
append :linked_files, ".env.production"
