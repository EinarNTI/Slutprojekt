  def start_db
    db = SQLite3::Database.new("db/db.db")
    db.results_as_hash = true
    return db
  end

  def search_user(username)
    return start_db.execute("SELECT * FROM users WHERE name = ?", username)[0]
  end

  def create_user(username, password)
    start_db.execute("INSERT INTO users (name, psw_dig) VALUES (?, ?)", [username, password])
  end

  def find_userID(username)
    return start_db.execute("SELECT id FROM users WHERE name = ?", username)[0]["id"]
  end

  def find_users_likes(id)
    db = start_db
    db.results_as_hash = false
    return db.execute("SELECT post_id FROM user_post_like_rel WHERE user_id == ?", id)
  end

  def find_users_name(id)
    row = start_db.execute("SELECT name FROM users WHERE id == ?", id)[0]
    return row ? row["name"] : nil
  end

  def get_all_posts
    start_db.execute("SELECT posts.*, users.name FROM posts INNER JOIN users ON posts.user_id = users.id ORDER BY posts.id DESC")
  end

  def get_all_likes
    db = start_db
    db.results_as_hash = false
    db.execute("SELECT post_id FROM user_post_like_rel")
  end

  def get_filtered_posts(filter)
    return start_db.execute("SELECT posts.*, users.name FROM posts INNER JOIN users ON posts.user_id = users.id WHERE users.id = ?", filter)
  end

  def create_post(content, username)
    start_db.execute("INSERT INTO posts (content, user_id) VALUES (?,?)", [content, username])
  end

  def send_like(user_id, post_id)
    start_db.execute("INSERT INTO user_post_like_rel (user_id, post_id) VALUES (?, ?)", [user_id, post_id])
  end

  def remove_like(user_id, post_id)
    start_db.execute("DELETE FROM user_post_like_rel WHERE user_id == ? AND post_id == ?", [user_id, post_id])
  end

  def get_post_owner_id(post_id)
    return start_db.execute("SELECT user_id FROM posts WHERE id == ?", post_id)[0]["user_id"]
  end

  def update_post(content, id)
    start_db.execute("UPDATE posts SET content = ? WHERE id = ?", [content, id])
  end

  def delete_post(id)
    db = start_db
    db.execute("DELETE FROM posts WHERE id == ?", id)
    db.execute("DELETE FROM user_post_like_rel WHERE post_id == ?", id)
  end

  def delete_account(id)
    db = start_db
    db.execute("DELETE FROM users WHERE id == ?", id)
    db.execute("DELETE FROM posts WHERE user_id == ?", id)
    db.execute("DELETE FROM user_post_like_rel WHERE user_id == ?", id)
  end