# @!parse
#   class App < Sinatra::Base
#   end
#
# This Sinatra application provides a simple social media platform
# with user accounts, posts, and likes functionality.
#
# @author [Einar Söderberg Beckman]
# @version 1.0
# @license MIT

require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require 'sinatra/flash'
require_relative './model/model.rb'

enable :sessions

include Model

set :login_attempts, {}

# @!method before_posts_filter
# Protects post-related routes by requiring user authentication.
# Redirects to login page if user is not logged in.
before '/posts/*' do
  if session[:userID_cookie] == nil
    redirect("/account/login")
  end
end

# @!method before_posts_index_filter
# Protects the posts index route by requiring user authentication.
# Redirects to login page if user is not logged in.
before '/posts' do
  if session[:userID_cookie] == nil
    redirect("/account/login")
  end
end

# @!method before_set_user_id
# Sets the current session user ID for every request.
# This makes the current user available in views and route handlers.
before do
  @user_id = session[:userID_cookie]
end

# @!method get_account_login
# Displays the login form for user authentication.
#
# @return [String] The rendered login page
get '/account/login' do
  slim(:"accounts/index")
end

# @!method post_account_login
# Handles user login authentication with rate limiting.
# Validates credentials and manages login attempts per IP.
#
# @param [String] username The username entered by the user
# @param [String] password The password entered by the user
# @return [void] Redirects to posts or back to login with flash message
post '/account/login' do
  user_info = search_user params[:username]

  t = Time.now.min
  ip = request.ip

  settings.login_attempts[ip] ||= { minute: t, count: 0 }

  if settings.login_attempts[ip][:minute] != t
    settings.login_attempts[ip] = { minute: t, count: 0 }
  end

  settings.login_attempts[ip][:count] += 1

  if settings.login_attempts[ip][:count] > 14
    flash[:notice] = "Too many requests"
    redirect('/posts')
  end

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

# @!method get_account_new
# Displays the registration form for new users.
#
# @return [String] The rendered registration page
get '/account/new' do
  slim(:"accounts/new")
end

# @!method post_account
# Handles user registration with validation.
# Creates a new user account if validation passes.
#
# @param [String] username The desired username (3-10 characters)
# @param [String] password The desired password (3-10 characters)
# @return [void] Redirects to posts or back to registration with flash message
post '/account' do
  if params[:username].length < 3 or params[:password].length < 3 or params[:username].length > 10 or params[:password].length > 10
    flash[:notice] = "Username and password must be at least 3 characters long, and max 10 characters."
    redirect("/account/new")
  elsif search_user(params[:username]) != nil
    flash[:notice] = "Username is already taken"
    redirect("/account/new")
  elsif params[:password] != params[:password_confirmation]
    flash[:notice] = "Password and password confirmation must match"
    redirect("/account/new")
  else
    create_user(params[:username], BCrypt::Password.create(params[:password]))
    session[:userID_cookie] = find_userID params[:username]
    redirect("/posts")
  end
end

# @!method get_account_logout
# Logs out the current user by clearing the session.
#
# @return [void] Redirects to login page
get '/account/logout' do
  session[:userID_cookie] = nil
  redirect("/account/login")
end

# @!method get_account_update
# Displays the user account edit form.
# Only the account owner or an admin may access this page.
#
# @param [Integer] id The ID of the account to edit
# @return [String] The rendered account edit page or a redirect if unauthorized
get '/account/:id/update' do
  if session[:userID_cookie] == params[:id].to_i or is_admin(session[:userID_cookie]) == 1
    @username = find_users_name(params[:id])
    @user_to_update = params[:id]
    slim(:"accounts/edit")
  else
    redirect("/posts")
  end
end

# @!method post_account_update
# Updates account information for the specified user.
# Only the account owner or an admin may perform the update.
# Validates username length, password length, and password confirmation.
#
# @param [Integer] id The ID of the account to update
# @param [String] username The new username
# @param [String] password The new password
# @param [String] password_confirmation The password confirmation
# @return [void] Redirects to posts or back to the account edit page on failure
post '/account/:id/update' do
  if session[:userID_cookie] == params[:id].to_i or is_admin(session[:userID_cookie]) == 1
    if params[:username].length < 3 or params[:password].length < 3 or params[:username].length > 10 or params[:password].length > 10
      flash[:notice] = "Username and password must be at least 3 characters long, and max 10 characters."
      redirect("/account/#{params[:id]}/update")
    elsif search_user(params[:username]) != nil
      flash[:notice] = "Username is already taken"
      redirect("/account/#{params[:id]}/update")
    elsif params[:password] != params[:password_confirmation]
      flash[:notice] = "Password and password confirmation must match"
      redirect("/account/#{params[:id]}/update")
    else
      update_user(params[:id], params[:username], BCrypt::Password.create(params[:password]))
      redirect("/posts")
    end
  else
    redirect("/posts")
  end
end

# @!method get_account_id
# Redirects to filtered posts for a specific user account.
#
# @param [Integer] id The user ID to filter posts by
# @return [void] Redirects to filtered posts page
get '/account/:id' do
  redirect("/posts/filter/#{params[:id]}")
end

# @!method get_root
# Redirects to the posts index page.
#
# @return [void] Redirects to /posts
get '/' do
  redirect 'posts'
end

# @!method get_posts
# Displays all posts with user likes and interaction data.
# Requires user authentication.
#
# @return [String] The rendered posts index page
get '/posts' do
  @likes = find_users_likes(session[:userID_cookie])

  @user_id = session[:userID_cookie]
  @username = find_users_name(session[:userID_cookie])
  @admin = is_admin(session[:userID_cookie])

  @posts = get_all_posts

  @all_likes = get_all_likes

  slim(:"posts/index")
end

# @!method get_posts_filter
# Displays posts filtered by a specific user ID.
# Requires user authentication.
#
# @param [Integer] filter The user ID to filter posts by
# @return [String] The rendered filtered posts page
get '/posts/filter/:filter' do
  @user_id = session[:userID_cookie]

  @username = find_users_name(session[:userID_cookie])

  @likes = find_users_likes(session[:userID_cookie])

  @posts = get_filtered_posts(params[:filter].to_i)

  @all_likes = get_all_likes

  slim(:"posts/index")
end

# @!method get_posts_create
# Displays the form for creating a new post.
# Requires user authentication.
#
# @return [String] The rendered new post form
get '/posts/create' do
  slim(:"posts/new")
end

# @!method post_posts
# Creates a new post with validation.
# Requires user authentication and uses the current session user as the author.
#
# @param [String] content The post content (1-255 characters)
# @return [void] Redirects to posts index; flashes an error if validation fails
post '/posts' do
  content = params[:content]
  if content == "" or content.length > 255
    flash[:notice] = "Post content must be between 1 and 255 characters long"
  else
    create_post(content, session[:userID_cookie])
  end
  redirect("/posts")
end

# @!method post_posts_like
# Adds a like to a specific post.
# Requires user authentication.
#
# @param [Integer] postId The ID of the post to like
# @return [void] Redirects to posts index
post '/posts/:postId/like' do
  @user_id = session[:userID_cookie]
  
  send_like(session[:userID_cookie], params[:postId])
  
  redirect("/posts")
end

# @!method post_posts_unlike
# Removes a like from a specific post.
# Requires user authentication.
#
# @param [Integer] postId The ID of the post to unlike
# @return [void] Redirects to posts index
post '/posts/:postId/unlike' do
  @user_id = session[:userID_cookie]
  
  remove_like(session[:userID_cookie], params[:postId])
  
  redirect("/posts")
end

# @!method get_posts_update
# Displays the edit form for a specific post.
# Only allows the post owner to edit.
# Requires user authentication.
#
# @param [Integer] id The ID of the post to edit
# @return [String] The rendered edit form or redirects if unauthorized
get '/posts/:id/update' do
  if session[:userID_cookie] == get_post_owner_id(params[:id]) or is_admin(session[:userID_cookie]) == 1
    @post = get_post(params[:id])
    slim(:"posts/edit")
  else
    redirect("/posts")
  end
end

# @!method post_posts_update
# Updates a specific post with validation.
# Only allows the post owner or an admin to update.
# Requires user authentication.
#
# @param [Integer] id The ID of the post to update
# @param [String] content The new post content (1-255 characters)
# @return [void] Redirects to posts index after updating or validation failure
post '/posts/:id/update' do
  if session[:userID_cookie] == get_post_owner_id(params[:id]) or is_admin(session[:userID_cookie]) == 1
    if params["content"] == "" or params["content"].length > 255
      flash[:notice] = "Post content must be between 1 and 255 characters long"
    else
      update_post(params["content"], params[:id])
    end
  end

  redirect("/posts")
end

# @!method post_posts_delete
# Deletes a specific post.
# Only allows the post owner to delete.
# Requires user authentication.
#
# @param [Integer] id The ID of the post to delete
# @return [void] Redirects to posts index
post '/posts/:id/delete' do
  if session[:userID_cookie] == get_post_owner_id(params[:id]) or is_admin(session[:userID_cookie]) == 1
    delete_post(params[:id])
  end
  redirect "/posts"
end

# @!method post_account_delete
# Deletes a user account by ID.
# Requires user authentication.
# Logs out the current session only when a user deletes their own account.
#
# @param [Integer] id The ID of the account to delete
# @return [void] Redirects to posts index
post '/account/:id/delete' do
  deleter = session[:userID_cookie]
  if session[:userID_cookie] == params[:id].to_i or is_admin(session[:userID_cookie]) == 1
    delete_account(params[:id])
    
    if deleter == params[:id].to_i
      session[:userID_cookie] = nil
    end
  end
  redirect('/posts')
end