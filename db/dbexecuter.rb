require 'sqlite3'

db = SQLite3::Database.new("db.db")
command = gets.chomp
db.execute(command)