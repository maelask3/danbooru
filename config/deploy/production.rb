set :user, "danbooru"
set :rails_env, "production"
server "danbooru.mthree.es", :roles => %w(web app), :primary => true, :user => "danbooru"

set :linked_files, fetch(:linked_files, []).push(".env.production")
set :rbenv_path, "/home/danbooru/.rbenv"
