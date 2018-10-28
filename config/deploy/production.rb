set :user, "danbooru"
set :rails_env, "production"
<<<<<<< HEAD
server "danbooru.mthree.es", :roles => %w(web app db), :primary => true, :user => "danbooru"

set :linked_files, fetch(:linked_files, []).push(".env.production")
set :rbenv_path, "/home/danbooru/.rbenv"
=======
server "kagamihara", :roles => %w(web app db), :primary => true
server "shima", :roles => %w(web app)
server "saitou", :roles => %w(web app)
server "oogaki", :roles => %w(worker)

set :linked_files, fetch(:linked_files, []).push(".env.production")
set :rbenv_path, "/home/danbooru/.rbenv"
>>>>>>> 271c50d1c88315d35d2b3161d0c7559001398455
