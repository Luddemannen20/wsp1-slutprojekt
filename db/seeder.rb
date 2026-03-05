require 'sqlite3'
require_relative '../config'

class Seeder

  def self.seed!
    puts "Using db file: #{DB_PATH}"
    puts "🧹 Dropping old tables..."
    drop_tables
    puts "🧱 Creating tables..."
    create_tables
    puts "🍎 Populating tables..."
    populate_tables
    puts "✅ Done seeding the database!"
  end

  def self.drop_tables
    db.execute('DROP TABLE IF EXISTS recipes')
  end

  def self.create_tables
    db.execute('CREATE TABLE recipes (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                time INTEGER,
                description TEXT,
                category INTEGER)')
  end

  def self.populate_tables
    db.execute('INSERT INTO recipes (name, time, description, category) VALUES ("Pasta Carbonara", 20, "Krämig pasta med bacon.", 0)')
    db.execute('INSERT INTO recipes (name, time, description, category) VALUES ("Grekisk sallad", 10, "Tomat, gurka, fetaost och oliver.", 1)')
    db.execute('INSERT INTO recipes (name, time, description, category) VALUES ("Kycklinggryta", 45, "Gryta med kyckling och curry.", 0)')
    db.execute('INSERT INTO recipes (name, time, description, category) VALUES ("Kall pastasallad", 15, "Serveras kall med dressing.", 1)')
  end

  private

  def self.db
    return @db if @db
    @db = SQLite3::Database.new('db/sqlite.db')
    @db.results_as_hash = true
    @db
  end

  def self.drop_tables
    db.execute('DROP TABLE IF EXISTS users')
  end

  def self.create_tables
    db.execute('CREATE TABLE users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT NOT NULL,
                password TEXT NOT NULL)')
  end

  def self.populate_tables
    password_hashed = Bcrypt::Password.create("123")
    p "Storing hashed password (#{password_hashed}) to DB. Clear text password (123) never saved."
    db.execute('INSERT INTO users (username, password) VALUES (?, ?)', ["Ludvig", password_hashed])
  end
end

Seeder.seed!