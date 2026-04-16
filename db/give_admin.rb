require 'sqlite3'

db = SQLite3::Database.new("db.db")
name = gets.chomp
db.execute("UPDATE users SET admin = 1 WHERE name == ?", name)