require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

enable :sessions

before do
  session[:userID_cookie] = 1
  if session[:userID_cookie] == nil
    slim(:login)
  end
end

get '/' do
  redirect 'posts'
end

get '/posts' do
  db = db()
  db.results_as_hash = false
  @likes = db.execute("SELECT post_id FROM user_post_like_rel WHERE user_id == ?", session[:userID_cookie])

  db.results_as_hash = true
  @user_id = session[:userID_cookie]
  @username = db.execute("SELECT name FROM users WHERE id == ?", session[:userID_cookie])[0]["name"]

  @posts = db.execute("SELECT posts.*, users.name FROM posts INNER JOIN users ON posts.user_id")

  slim(:index)
end

get '/posts/filter/:filter' do
  @userID_cookie = session[:userID_cookie]

  db = db()
  if params[:filter] == "mine"
    @posts = db.execute("SELECT * FROM posts INNER JOIN users ON posts.user_id WHERE users.name = ?", session[:userID_cookie])
  else
    @posts = db.execute("SELECT * FROM posts INNER JOIN users ON posts.user_id")
  end

  slim(:index)
end

get '/posts/create' do
  slim(:create)
end

post '/posts/create' do
  db = db()
  content = params[:content]
  username = session[:userID_cookie]

  db.execute("INSERT INTO posts (content, user_id) VALUES (?,?)", [content, username])
  redirect("/posts")
end

post '/posts/like/:postId' do
  db = db()
  @user_id = session[:userID_cookie]
  db.execute("INSERT INTO user_post_like_rel (user_id, post_id) VALUES (?, ?)", [session[:userID_cookie], params[:postId]])
  redirect("/posts")
end

post '/posts/unlike/:postId' do
  db = db()
  @user_id = session[:userID_cookie]
  db.execute("DELETE FROM user_post_like_rel WHERE user_id == ? AND post_id == ?", [session[:userID_cookie], params[:postId]])
  redirect("/posts")
end

get '/posts/edit/:id' do
  db = db()

  if session[:userID_cookie] == db.execute("SELECT user_id FROM posts WHERE id == ?", params[:id])[0]["user_id"]
    @post_id = params[:id]
    slim(:edit)
  else
    redirect("/posts")
  end
end

post '/posts/edit/:id' do
  db = db()

  db.execute("UPDATE posts SET content = ? WHERE id = ?", [params["content"], params[:id]])

  redirect("/posts")
end

def db()
  db = SQLite3::Database.new("db/db.db")
  db.results_as_hash = true
  return db
end