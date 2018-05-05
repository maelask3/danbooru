set :user, "danbooru"
set :rails_env, "production"
server "danbooru.mthree.es", :roles => %w(web app), :primary => true, :user => "danbooru"
server "db02.ux.mthree.es", :roles => %w(db), :user => "danbooru"

set :linked_files, fetch(:linked_files, []).push(".env.production")
set :rbenv_path, "/home/danbooru/.rbenv"
