require 'sqlite3'

db = SQLite3::Database.new("db.db")


def seed!(db)
  puts "Using db file: db/todos.db"
  puts "🧹 Dropping old tables..."
  drop_tables(db)
  puts "🧱 Creating tables..."
  create_tables(db)
  puts "🍎 Populating tables..."
  populate_tables(db)
  puts "✅ Done seeding the database!"
end

def drop_tables(db)
  db.execute('DROP TABLE IF EXISTS users')
  db.execute('DROP TABLE IF EXISTS posts')
  db.execute('DROP TABLE IF EXISTS user_post_like_rel')
  db.execute('DROP TABLE IF EXISTS comments')
end

def create_tables(db)
  db.execute('CREATE TABLE users (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT, 
              psw_dig TEXT)')
  db.execute('CREATE TABLE posts (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              content TEXT,
              user_id INTEGER,
              FOREIGN KEY(user_id) REFERENCES users(id))')
  db.execute('CREATE TABLE user_post_like_rel (
              user_id INTEGER,
              post_id INTEGER,
              FOREIGN KEY(user_id) REFERENCES users(id),
              FOREIGN KEY(post_id) REFERENCES posts(id))')
  db.execute('CREATE TABLE comments (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              content TEXT,
              user_id INTEGER,
              post_id INTEGER,
              FOREIGN KEY(user_id) REFERENCES users(id),
              FOREIGN KEY(post_id) REFERENCES posts(id))')
end

def populate_tables(db)
  db.execute('INSERT INTO posts (content, user_id) VALUES ("Köp mjölk", 1)')
  db.execute('INSERT INTO users (name, psw_dig) VALUES ("Alice", "hashed_password_123")')
end


seed!(db)





