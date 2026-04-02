require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require 'sinatra/flash'
require_relative './model/model.rb'

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
  slim(:"accounts/index")
end

post '/account/login' do
  user_info = search_user params[:username]
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
  slim(:"accounts/new")
end

post '/account' do
  if params[:username].length < 3 or params[:password].length < 3 or params[:username].length > 10 or params[:password].length > 10
    flash[:notice] = "Username and password must be at least 3 characters long, and max 10 characters."
    redirect("/account/new")
  elsif search_user(params[:username]) != nil
    flash[:notice] = "Username is already taken"
    redirect("/account/new")
  else
    create_user(params[:username], BCrypt::Password.create(params[:password]))
    session[:userID_cookie] = find_userID params[:username]
    redirect("/posts")
  end
end

get '/account/logout' do
  session[:userID_cookie] = nil
  redirect("/account/login")
end

get '/account/:id' do
  redirect("/posts/filter/#{params[:id]}")
end

get '/' do
  redirect 'posts'
end

get '/posts' do
  @likes = find_users_likes(session[:userID_cookie])

  @user_id = session[:userID_cookie]
  @username = find_users_name(session[:userID_cookie])

  @posts = get_all_posts

  @all_likes = get_all_likes

  slim(:"posts/index")
end

get '/posts/filter/:filter' do
  @user_id = session[:userID_cookie]

  @username = find_users_name(session[:userID_cookie])

  @likes = find_users_likes(session[:userID_cookie])

  @posts = get_filtered_posts(params[:filter].to_i)

  @all_likes = get_all_likes

  slim(:"posts/index")
end

get '/posts/create' do
  slim(:"posts/new")
end

post '/posts' do
  content = params[:content]
  username = session[:userID_cookie]
  if content == "" or content.length > 255
    flash[:notice] = "Post content must be between 1 and 255 characters long"
  else
    create_post(content, username)
  end
  redirect("/posts")
end

post '/posts/:postId/like' do
  @user_id = session[:userID_cookie]
  
  send_like(session[:userID_cookie], params[:postId])
  
  redirect("/posts")
end

post '/posts/:postId/unlike' do
  @user_id = session[:userID_cookie]
  
  remove_like(session[:userID_cookie], params[:postId])
  
  redirect("/posts")
end

get '/posts/:id/update' do
  if session[:userID_cookie] == get_post_owner_id(params[:id])
    @post_id = params[:id]
    slim(:"posts/edit")
  else
    redirect("/posts")
  end
end

post '/posts/:id/update' do
  if session[:userID_cookie] == get_post_owner_id(params[:id])
    if params["content"] == "" or params["content"].length > 255
      flash[:notice] = "Post content must be between 1 and 255 characters long"
    else
      update_post(params["content"], params[:id])
    end
  end

  redirect("/posts")
end

post '/posts/:id/delete' do
  if session[:userID_cookie] == get_post_owner_id(params[:id])
    delete_post(params[:id])
  end
  redirect "/posts"
end

post '/account/delete' do
  delete_account(session[:userID_cookie])
  session[:userID_cookie9] = nil
  redirect('/posts')
end