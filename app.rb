require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require 'sinatra/flash'

enable :sessions

before '/posts/*' do
  if session[:userID_cookie] == nil
    redirect("/account/login")
  end
end

before '/posts' do
  if session[:userID_cookie] == nil
    redirect("/account/login")
  end
end

get '/account/login' do
  slim(:login)
end

post '/account/login' do
  db = db()
  user_info = db.execute("SELECT * FROM users WHERE name = ?", params[:username])[0]
  if user_info != nil
    if BCrypt::Password.new(user_info["psw_dig"]) == params[:password] and params[:username] != "" and params[:password] != ""
      session[:userID_cookie] = user_info["id"]
      redirect("/posts")
    else
      flash[:notice] = "Incorrect username or password."
      redirect("/account/login")
    end
  else
    flash[:notice] = "User does not exist"
    redirect("/account/login")
  end
end

get '/account/new' do
  slim(:create_account)
end

post '/account' do
  db = db()

  if params[:username].length < 3 or params[:password].length < 3 or params[:username].length > 10 or params[:password].length > 10
    flash[:notice] = "Username and password must be at least 3 characters long, and max 10 characters."
    redirect("/account/new")
  elsif db.execute("SELECT name FROM users WHERE name = ?", params[:username]).length > 0
    flash[:notice] = "Username is already taken"
    redirect("/account/new")
  else
    if db.execute("SELECT * FROM users WHERE name = ?", params[:username]) == []
      db.execute("INSERT INTO users (name, psw_dig) VALUES (?, ?)", [params[:username], BCrypt::Password.create(params[:password])])
      session[:userID_cookie] = db.execute("SELECT id FROM users WHERE name = ?", params[:username])[0]["id"]
      redirect("/posts")
    end
  end
end

get '/account/logout' do
  session[:userID_cookie] = nil
  redirect("/account/login")
end

get '/account/:id' do
  
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

  @posts = db.execute("SELECT posts.*, users.name FROM posts INNER JOIN users ON posts.user_id = users.id ORDER BY posts.id DESC")

  db.results_as_hash = false
  @all_likes = db.execute("SELECT post_id FROM user_post_like_rel")

  slim(:index)
end

get '/posts/filter/:filter' do
  db = db()

  @user_id = session[:userID_cookie]

  @username = db.execute("SELECT name FROM users WHERE id == ?", session[:userID_cookie])[0]["name"]

  @likes = db.execute("SELECT post_id FROM user_post_like_rel WHERE user_id == ?", session[:userID_cookie])

  @posts = db.execute("SELECT posts.*, users.name FROM posts INNER JOIN users ON posts.user_id = users.id WHERE users.id = ?", params[:filter].to_i)

  db.results_as_hash = false
  @all_likes = db.execute("SELECT post_id FROM user_post_like_rel")

  slim(:index)
end

get '/posts/create' do
  slim(:create)
end

post '/posts' do
  db = db()
  content = params[:content]
  username = session[:userID_cookie]
  if content == "" or content.length > 255
    flash[:notice] = "Post content must be between 1 and 255 characters long"
  else
    db.execute("INSERT INTO posts (content, user_id) VALUES (?,?)", [content, username])
  end
  redirect("/posts")
end

post '/posts/:postId/like' do
  db = db()
  @user_id = session[:userID_cookie]
  
  db.execute("INSERT INTO user_post_like_rel (user_id, post_id) VALUES (?, ?)", [session[:userID_cookie], params[:postId]])
  
  redirect("/posts")
end

post '/posts/:postId/unlike' do
  db = db()
  @user_id = session[:userID_cookie]
  
  db.execute("DELETE FROM user_post_like_rel WHERE user_id == ? AND post_id == ?", [session[:userID_cookie], params[:postId]])
  
  redirect("/posts")
end

get '/posts/:id/update' do
  db = db()

  if session[:userID_cookie] == db.execute("SELECT user_id FROM posts WHERE id == ?", params[:id])[0]["user_id"]
    @post_id = params[:id]
    slim(:edit)
  else
    redirect("/posts")
  end
end

post '/posts/:id/update' do
  db = db()
  if session[:userID_cookie] == db.execute("SELECT user_id FROM posts WHERE id == ?", params[:id])
    if content == "" or content.length > 255
      flash[:notice] = "Post content must be between 1 and 255 characters long"
    else
      db.execute("UPDATE posts SET content = ? WHERE id = ?", [params["content"], params[:id]])
    end
  end

  redirect("/posts")
end

def db()
  db = SQLite3::Database.new("db/db.db")
  db.results_as_hash = true
  return db
end