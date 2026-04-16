# Model module containing database operations for the social media application.
#
# This module provides methods to interact with the SQLite database,
# including user management, posts, and likes functionality.
#
# @author [Einar Söderberg Beckman]
# @version 1.0

module Model

  # Initializes and returns a new SQLite database connection.
  #
  # @return [SQLite3::Database] The database connection with results as hash enabled
  def start_db
    db = SQLite3::Database.new("db/db.db")
    db.results_as_hash = true
    return db
  end

  # Searches for a user by username.
  #
  # @param [String] username The username to search for
  # @return [Hash, nil] User data hash if found, nil otherwise
  def search_user(username)
    return start_db.execute("SELECT * FROM users WHERE name == ?", username)[0]
  end

  # Creates a new user in the database.
  #
  # @param [String] username The username for the new user
  # @param [String] password The hashed password for the new user
  # @return [void]
  def create_user(username, password)
    start_db.execute("INSERT INTO users (name, psw_dig, admin) VALUES (?, ?, 0)", [username, password])
  end

  # Finds the user ID for a given username.
  #
  # @param [String] username The username to find the ID for
  # @return [Integer] The user ID
  def find_userID(username)
    return start_db.execute("SELECT id FROM users WHERE name == ?", username)[0]["id"]
  end

  # Retrieves all post IDs that a user has liked.
  #
  # @param [Integer] id The user ID
  # @return [Array<Array>] Array of arrays containing post IDs
  def find_users_likes(id)
    db = start_db
    db.results_as_hash = false
    return db.execute("SELECT post_id FROM user_post_like_rel WHERE user_id == ?", id)
  end

  # Finds the username for a given user ID.
  #
  # @param [Integer] id The user ID
  # @return [String, nil] The username if found, nil otherwise
  def find_users_name(id)
    row = start_db.execute("SELECT name FROM users WHERE id == ?", id)[0]
    return row ? row["name"] : nil
  end

  # Retrieves all posts with associated user information, ordered by ID descending.
  #
  # @return [Array<Hash>] Array of post hashes with user names
  def get_all_posts
    start_db.execute("SELECT posts.*, users.name FROM posts INNER JOIN users ON posts.user_id = users.id ORDER BY posts.id DESC")
  end

  # Retrieves a single post with associated user information.
  #
  # @param [Integer] post_id The post ID
  # @return [Hash, nil] The post hash with user name if found, nil otherwise
  def get_post(post_id)
    return start_db.execute("SELECT posts.*, users.name FROM posts INNER JOIN users ON posts.user_id = users.id WHERE posts.id == ?", post_id)[0]
  end

  # Retrieves all liked post IDs across all users.
  #
  # @return [Array<Array>] Array of arrays containing post IDs that have been liked
  def get_all_likes
    db = start_db
    db.results_as_hash = false
    db.execute("SELECT post_id FROM user_post_like_rel")
  end

  # Retrieves posts filtered by a specific user ID.
  #
  # @param [Integer] filter The user ID to filter posts by
  # @return [Array<Hash>] Array of post hashes for the specified user
  def get_filtered_posts(filter)
    return start_db.execute("SELECT posts.*, users.name FROM posts INNER JOIN users ON posts.user_id = users.id WHERE users.id == ?", filter)
  end

  # Creates a new post in the database.
  #
  # @param [String] content The post content
  # @param [Integer] user_id The user ID of the post author
  # @return [void]
  def create_post(content, user_id)
    start_db.execute("INSERT INTO posts (content, user_id) VALUES (?,?)", [content, user_id])
  end

  # Adds a like relationship between a user and a post.
  #
  # @param [Integer] user_id The ID of the user liking the post
  # @param [Integer] post_id The ID of the post being liked
  # @return [void]
  def send_like(user_id, post_id)
    db = start_db 
    if db.execute("SELECT user_id, post_id FROM user_post_like_rel WHERE user_id == ? AND post_id == ?", [user_id, post_id]).length < 1
      db.execute("INSERT INTO user_post_like_rel (user_id, post_id) VALUES (?, ?)", [user_id, post_id])
    end
  end

  # Removes a like relationship between a user and a post.
  #
  # @param [Integer] user_id The ID of the user unliking the post
  # @param [Integer] post_id The ID of the post being unliked
  # @return [void]
  def remove_like(user_id, post_id)
    start_db.execute("DELETE FROM user_post_like_rel WHERE user_id == ? AND post_id == ?", [user_id, post_id])
  end

  # Retrieves the owner ID of a specific post.
  #
  # @param [Integer] post_id The ID of the post
  # @return [Integer] The user ID of the post owner
  def get_post_owner_id(post_id)
    return start_db.execute("SELECT user_id FROM posts WHERE id == ?", post_id)[0]["user_id"]
  end

  # Updates the content of a specific post.
  #
  # @param [String] content The new content for the post
  # @param [Integer] id The ID of the post to update
  # @return [void]
  def update_post(content, id)
    start_db.execute("UPDATE posts SET content = ? WHERE id == ?", [content, id])
  end

  # Deletes a post and all associated likes.
  #
  # @param [Integer] id The ID of the post to delete
  # @return [void]
  def delete_post(id)
    db = start_db
    db.execute("DELETE FROM posts WHERE id == ?", id)
    db.execute("DELETE FROM user_post_like_rel WHERE post_id == ?", id)
  end

  # Deletes a user account and all associated posts and likes.
  #
  # @param [Integer] id The ID of the user account to delete
  # @return [void]
  def delete_account(id)
    db = start_db
    db.execute("DELETE FROM users WHERE id == ?", id)
    db.execute("DELETE FROM posts WHERE user_id == ?", id)
    db.execute("DELETE FROM user_post_like_rel WHERE user_id == ?", id)
  end

  # Checks whether a user has admin privileges.
  #
  # @param [Integer] id The user ID
  # @return [Integer, nil] The admin flag (1 if admin, 0 if not), nil if user not found
  def is_admin(id)
    return start_db.execute("SELECT admin FROM users WHERE id == ?", id)[0]["admin"]
  end

  # Updates a user's username and password hash.
  #
  # @param [Integer] id The ID of the user to update
  # @param [String] username The new username
  # @param [String] password The new hashed password
  # @return [void]
  def update_user(id, username, password)
    start_db.execute("UPDATE users SET name = ?, psw_dig = ? WHERE id == ?", [username, password, id])
  end
end