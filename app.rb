require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

enable :sessions

before do
  session[:username_cookie] = "Alice"
end

get '/' do
  redirect 'posts'
end

get '/posts' do
  @username_cookie = session[:username_cookie]

  db = db()

  @posts = db.execute("SELECT * FROM posts INNER JOIN users ON posts.user_id")

  slim(:index)
end

get '/posts/filter/:filter' do
  @username_cookie = session[:username_cookie]

  db = db()
  if params[:filter] == "mine"
    @posts = db.execute("SELECT * FROM posts INNER JOIN users ON posts.user_id WHERE users.name = ?", session[:username_cookie])
  else
    @posts = db.execute("SELECT * FROM posts INNER JOIN users ON posts.user_id")
  end

  slim(:index)
end

get '/posts/create' do
  slim(:create)
end

post '/posts/create' do
  
end

def db()
  db = SQLite3::Database.new("db/db.db")
  db.results_as_hash = true
  return db
end